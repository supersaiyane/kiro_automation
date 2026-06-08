---
id: incident_response_runbook
version: 1.0.0
owners: [security_engineer, sre]
tags: [security, incident-response, ir, forensics, nist-800-61]
when_to_use: |
  A security incident is suspected or confirmed (data exfil, ransomware,
  account takeover, malicious code commit, exposed credentials). Apply
  these phases regardless of incident size. The cost of NOT having the
  runbook ready is measured in hours of confused leadership during a
  breach.
inputs:
  - alert_or_report, asset_inventory, contact_tree
outputs:
  - "ir_artifacts: timeline + containment actions + IOCs + postmortem"
---

# Security Incident Response (NIST SP 800-61 r2 adapted)

> The worst time to design your incident response is during an
> incident. The runbook is rehearsed BEFORE the alert.

## The six phases (NIST 800-61)

```
1. PREPARE  ──► (ongoing, not in-incident)
2. DETECT   ──► alert fires, ticket opens
3. ANALYZE  ──► triage: is this real? what's the scope?
4. CONTAIN  ──► stop the bleeding (short-term + long-term)
5. ERADICATE──► remove attacker access + the vulnerability
6. RECOVER  ──► restore, monitor closely, exit IR mode
7. LESSONS  ──► postmortem (blameless), policy + control updates
```

Order matters. Do NOT eradicate before you've contained — you'll
tip off the attacker and lose telemetry.

## PREPARE (cold)

What must exist BEFORE the first alert:

- **Contact tree** with phone numbers (not just Slack). IR coordinator,
  on-call, legal, comms, executive sponsor. Tested quarterly.
- **Out-of-band comms** channel (Signal group, separate Slack workspace).
  Assume your primary chat is compromised.
- **Asset inventory** — what services run where, what data each holds,
  who owns each. Without this you can't scope.
- **Logging baseline** — auth logs, network flow logs, audit logs for
  90+ days hot. If you can't query, you can't analyze.
- **Pre-cut comms templates** — "we're investigating", "we've confirmed
  exposure of X", "we've contained and remediated."
- **Legal preservation list** — what to preserve under hold (logs,
  memory dumps, disk images). Talk to counsel BEFORE not during.
- **Drill cadence**: tabletop quarterly, full-fidelity drill annually.

## DETECT & ANALYZE — the first 60 minutes

```
First 5 min:
  [ ] IR coordinator declares incident, opens war-room channel
  [ ] Severity assigned (SEV-1/2/3) using your matrix
  [ ] Page legal counsel if SEV-1 (data exposure suspected)

First 30 min:
  [ ] Timeline started (UTC, one row per known event)
  [ ] Initial scope: which systems / data / accounts touched
  [ ] Decide containment strategy (kill switch? quarantine? watch?)

First 60 min:
  [ ] Comms sent to internal stakeholders (NOT customers yet)
  [ ] Containment decision made and executed
  [ ] Forensics evidence captured BEFORE any destructive action
```

**Severity matrix** (your version, calibrated to your business):

| SEV | Definition | Examples | Notify |
|---|---|---|---|
| 1 | Confirmed exposure of customer/regulated data, or active attacker in prod | Ransomware, exfil, prod RCE | Exec + legal + customers (per regulation) |
| 2 | Suspected exposure, or non-prod compromise with prod blast radius | Compromised employee account with prod access | Exec, legal review |
| 3 | Contained, low blast radius | Phishing click, no creds entered | IR team only |

## CONTAIN — stop the bleeding

Two tiers, both planned:

**Short-term containment** (minutes to hours):
- Rotate the credential, revoke the token, kill the session.
- Isolate the host (move to quarantine VLAN; do NOT power off if you
  want memory forensics).
- Block the IP / domain / hash at the network edge.
- Disable the user account.

**Long-term containment** (hours to days):
- Patch the vuln class that allowed entry.
- Rebuild affected hosts from known-good images.
- Rotate ALL credentials that touched the compromised system —
  service accounts, signing keys, SSH keys, API tokens.
- Re-issue customer-impacting secrets if relevant.

**Critical rule: preserve evidence first.** Memory dump → disk image
→ log export to write-once storage BEFORE any rebuild or wipe.
Chain of custody matters if law enforcement gets involved.

## ERADICATE — close the door

Once containment is firm:

1. Identify root cause. Not "they got in via SSH" — "they got in via
   SSH because the bastion was missing MFA enforcement after the
   2025-03-12 config drift, which happened because…"
2. Remove every persistence mechanism (cron jobs, systemd units, IAM
   roles, GitHub deploy keys, OAuth apps).
3. Patch the actual vulnerability class, not just the instance.
4. Hunt for the SAME indicator-of-compromise across the environment.
   Attackers rarely land in only one place.

## RECOVER — back to normal cautiously

- Restore from KNOWN-CLEAN backups, not from "the backup before
  Tuesday." Verify integrity by hash.
- Add enhanced monitoring on recovered systems for 30+ days
  (attacker re-entry is common in the first 2 weeks).
- Customer-facing recovery comms (post-mortem, what we did, what
  we changed). Be specific. Vague comms erode trust faster than
  the incident itself.

## LESSONS LEARNED — blameless postmortem within 14 days

Mandatory sections:
- **What happened** (factual timeline, UTC).
- **Detection** — how/when did we find out? Could we have found
  out earlier?
- **Containment** — what worked? What was clumsy?
- **Root cause** — five whys to a systemic cause, not a person.
- **Impact** — data, customers, dollars, hours, reputation.
- **Action items** — each with owner + due date + tracking ticket.
  Categorize by: prevent recurrence / detect faster / contain faster
  / recover faster.

The output is a document AND a set of tracked engineering work.
A postmortem without funded follow-up is theater.

## Comms — say it right or don't say it

- **Internal (within minutes)**: facts only, no speculation. "We are
  investigating a possible exposure of X. Status updates every 30
  min in #incident-2026-04-12."
- **Customer (only after legal review)**: what happened, what data,
  what you've done, what they should do, where to get help.
- **Regulators**: per jurisdiction. GDPR: 72h. CCPA, state laws,
  HIPAA, PCI all have specific windows. Legal owns this — your job
  is to give them facts on time.
- **Public**: only the spokesperson talks. Everyone else routes
  inquiries to them. NO speculation on cause until root cause is
  confirmed.

## Anti-patterns

- **Powering off the compromised host immediately.** You lose RAM
  evidence (process trees, encryption keys, network connections).
  Quarantine the network, not the power.
- **Wiping & restoring before forensics.** Once wiped, the
  investigation is over.
- **"We caught it, no need to tell anyone."** Many regulations
  require disclosure regardless of containment outcome.
- **The IR runbook lives in the affected system.** Wikis on
  compromised infra are useless during an incident. Keep IR
  docs on a separate trust boundary.
- **One person knows the playbook.** Run quarterly tabletops with
  a rotating IR coordinator.
- **Naming an attacker.** "It was China" is a legal nightmare
  without forensic certainty. Stick to TTPs (techniques) and IOCs
  (indicators).

## Tabletop drill template (quarterly, 90 min)

Scenario card (one example):

> "07:14 UTC: Datadog alerts on 1,200% spike in egress from
> `api-prod-3`. The on-call SRE Slacks you. There are no recent
> deploys. The host has a public IPv6 address and SSH is open to
> bastion only. What do you do in the next 15 minutes?"

Walk through it as if real. Time each phase. Identify the
weakest link (usually: someone doesn't know who decides on
containment authority).

## Validation that IR is real

- [ ] Last tabletop was within the last 90 days.
- [ ] Out-of-band comms channel was used in the last drill and
      everyone could join in < 5 min.
- [ ] You can pull 90+ days of auth logs in < 10 minutes.
- [ ] An on-call engineer can name the IR coordinator and the
      legal contact WITHOUT looking it up.
- [ ] The last postmortem produced ≥ 3 funded engineering items
      that are now CLOSED.
