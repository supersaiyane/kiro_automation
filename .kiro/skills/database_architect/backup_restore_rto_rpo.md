---
id: backup_restore_rto_rpo
version: 1.0.0
owners: [database_architect, sre, security_engineer]
tags: [backup, restore, rto, rpo, dr, pitr, postgres, mysql]
when_to_use: |
  Any production database. Backup that's never restored is
  decoration. RTO (Recovery Time Objective) + RPO (Recovery Point
  Objective) are the only numbers that matter; everything else
  is theater.
inputs:
  - data_value, downtime_cost_per_hour, compliance_requirements
outputs:
  - "dr_strategy: rto + rpo + backup tiers + restore drill cadence"
---

# Backup, Restore, RTO + RPO

> "We have backups" is a vibe. "We have a 15-minute RPO and a
> 30-minute RTO, last drilled 2026-04-20" is engineering. The
> difference is the business case during the postmortem.

## RTO and RPO — define them, then design for them

- **RTO** (Recovery Time Objective): max acceptable downtime
  during a recovery. "We can be down for 30 minutes before the
  business loses real money."
- **RPO** (Recovery Point Objective): max acceptable data loss.
  "We can lose the last 5 minutes of transactions, but not more."

Lower RTO/RPO = exponentially more expensive. Pick the right tier
per data type, not one number for everything.

## Tiered RTO/RPO model

```
Tier 1 — Critical (payments, ledger)
  RTO ≤ 30 sec, RPO = 0       → synchronous replica + auto-failover

Tier 2 — Core (user data, orders)
  RTO ≤ 30 min, RPO ≤ 1 min   → async replica + PITR + auto-failover

Tier 3 — Important (analytics, logs)
  RTO ≤ 4 hrs, RPO ≤ 1 hr     → daily backup + WAL ship

Tier 4 — Cold (archived events)
  RTO ≤ 24 hrs, RPO ≤ 1 day   → daily snapshot to object storage
```

## Backup types

### Logical backup (`pg_dump`, `mysqldump`)
- Pros: portable, version-agnostic, schema-aware.
- Cons: SLOW for large DBs; restore takes hours.
- Use for: pre-migration safety, dev/staging clones,
  cross-version moves.

### Physical backup (`pg_basebackup`, Percona XtraBackup)
- Pros: FAST; data files copied as-is.
- Cons: version-specific; full restore needed for partial recovery.
- Use for: production backup, fastest restore.

### Continuous archive + WAL ship (PITR)
- Pros: Recovery to ANY point in time, not just backup timestamps.
- Cons: WAL storage cost (small).
- Use for: production OLTP. THE BACKUP YOU NEED.

PITR = base backup (e.g., daily) + every WAL since. To restore
to 14:32:17, replay WAL from the last base backup up to that
exact timestamp.

## Backup retention policy

```
Hourly  → 24 hours
Daily   → 30 days
Weekly  → 12 weeks
Monthly → 12 months
Yearly  → 7 years (compliance window)
```

Storage cost is dominated by hourly + daily; older tiers are
cheap S3 Glacier.

## Where backups live

- **Same region**: fast restore, single failure domain. NEVER
  the only copy.
- **Cross-region** (replicated copy): survives region outage.
  Required for Tier 1 and Tier 2.
- **Cross-cloud / cross-vendor** (rare): survives vendor
  outage. Most teams skip; budget required.
- **Immutable object storage** (WORM, object-lock): protects
  against ransomware. AWS S3 Object Lock, Azure immutable blob.

## The restore drill — the ONLY metric that matters

A backup that's never restored has probability ~0 of working
when you need it. Drills:

- **Quarterly**: full restore from PITR to a non-prod env.
- **Monthly**: partial restore (one table, one tenant).
- **After every major schema change**: verify backup includes it.

Measure:
- Time from "start restore" to "DB serving queries" — that's
  your real RTO.
- Data integrity check (checksum some hot tables; compare to
  prod at the matching point in time).

A first-restore-drill regularly finds:
- Missing tables (excluded by old policy nobody remembered).
- Permissions that broke.
- Tools (pg_restore version) that don't exist in the recovery env.
- Encryption keys that aren't reachable.

## Disaster scopes — design for them

| Scope | Frequency | Plan |
|---|---|---|
| Bad query / table corrupt | Monthly | PITR to before the bad query |
| Node failure | Quarterly | Failover to replica |
| AZ failure | Yearly | Multi-AZ replicas |
| Region failure | Rare | Cross-region backup + replica |
| Cloud provider outage | Very rare | Cross-cloud backup (tier-specific) |
| Ransomware / malicious deletion | Rare but devastating | Immutable backup, separate creds |
| Catastrophic data corruption | Rare | Long-retention PITR (months) |

The ransomware case is the modern threat — IF the attacker also
has DB credentials, they can delete the backups. Mitigations:
- Backups owned by a SEPARATE IAM principal (only writes, no
  deletes from the DB account).
- Object lock / WORM at the storage layer.
- Vault credentials with short-lived tokens.

## Encryption + key management

- **Encrypt backups at rest** (KMS-managed key, NOT a static
  password in the backup script).
- **Encrypt in transit** to backup destination.
- Key rotation lifecycle documented; old keys retained as long
  as backups encrypted with them.

Loss of the encryption key = loss of the backup. Treat keys as
critical infra (same backup discipline applies — yes, back up
your KMS keys via the vendor's escape hatch).

## Backup validation — automated

```yaml
# CI / scheduled job
backup_validation:
  schedule: daily
  steps:
    - download latest backup
    - restore to ephemeral env
    - run SELECT count(*) FROM users; SELECT count(*) FROM orders;
    - compare counts to expected (within tolerance)
    - run a known-good query, compare result
    - shred ephemeral env
  on_failure: PAGE
```

If the backup is unrestorable, you want to know TODAY, not
during the incident.

## Point-in-time recovery walkthrough (Postgres)

```bash
# 1. Identify target time (from logs / incident comms)
target="2026-05-27 14:32:17 UTC"

# 2. Restore base backup
pg_basebackup -D /var/lib/postgresql/recovery -X stream

# 3. Configure recovery
cat > /var/lib/postgresql/recovery/recovery.signal
cat > /var/lib/postgresql/recovery/postgresql.auto.conf <<EOF
restore_command = 'aws s3 cp s3://wal-bucket/%f %p'
recovery_target_time = '$target'
recovery_target_action = 'pause'
EOF

# 4. Start, pause, validate
pg_ctl -D /var/lib/postgresql/recovery start
# Verify the state looks right
# pg_wal_replay_resume() once happy → promote to RW
```

Document EVERY step in the runbook. Practice in staging.

## Backup metrics worth tracking

- Time-since-last-successful-backup per tier.
- Time-since-last-successful-restore-test per tier.
- Backup size growth rate.
- Restore RTO (from drills).
- WAL retention vs storage limit.

## Anti-patterns

- **No restore drills.** Backups are theater until proven.
- **Backup credentials in the same account as the DB.** One
  compromise = both gone.
- **Single-region backup for a multi-region service.** Region
  outage = data loss + downtime.
- **`mysqldump` for a 500GB DB at peak load.** Locks tables;
  ages forever.
- **One person knows how to restore.** Bus-factor risk.
- **Backups encrypted with a static key in config.** Key
  rotation impossible.
- **WAL retention shorter than the restore window.** Can't PITR
  past your WAL horizon.
- **Skipping post-restore data integrity checks.** Restore looked
  OK; subtle corruption in cold rows nobody touches.

## Validation

- [ ] RTO + RPO documented per data tier.
- [ ] Backups stored cross-region for Tier 1 + 2.
- [ ] Restore drill executed within the last 90 days; result
      met RTO.
- [ ] Backups encrypted at rest with KMS-managed keys.
- [ ] Backup credentials are isolated from DB credentials.
- [ ] WAL retention exceeds the max PITR window in policy.
- [ ] Automated daily backup-validation job is green.
- [ ] An on-call engineer can complete a PITR in a non-prod env
      using only the runbook (no senior help) in under RTO.
