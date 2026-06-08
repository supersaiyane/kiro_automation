---
id: forensics_log_analysis_dfir
version: 1.0.0
owners: [security_engineer, sre]
tags: [dfir, forensics, log-analysis, evidence, chain-of-custody, threat-hunting]
when_to_use: |
  During or after a suspected security incident. Done right: actionable
  evidence + court-defensible chain of custody. Done wrong: contaminated
  evidence, inadmissible, attackers walk and lessons aren't learned.
inputs:
  - incident_scope, available_telemetry, regulatory_obligations
outputs:
  - "forensics_findings: timeline + IOCs + scope + root cause + chain of custody"
---

# Forensics, Log Analysis, DFIR

> The minute you suspect a breach, every decision either preserves or
> destroys evidence. Pull the laptop? Power it off? Log in to look?
> Each has consequences. DFIR is the discipline of making the right
> call under pressure.

## DFIR (Digital Forensics + Incident Response) phases

```
1. PREPARE      → tools, training, jump bag, retainers
2. IDENTIFY     → what happened, what's affected
3. CONTAIN      → stop the bleeding (preserving evidence)
4. ERADICATE    → remove attacker
5. RECOVER      → restore from clean
6. POST-MORTEM  → learn + improve
```

Phases 2-5 are the IR runbook (separate skill `incident_response_runbook`).
This skill focuses on the FORENSICS within those phases.

## Order of volatility — what to capture FIRST

When investigating a compromised host, evidence disappears fast:

```
1. CPU registers, cache         (lost on context switch — usually too late)
2. RAM, kernel state, processes (lost on poweroff)
3. Network state (sockets, ARP) (lost on disconnect/reboot)
4. Disk (free + slack space)    (lost on overwrite, decreasing odds)
5. Logs                         (lost on rotation)
6. Backups                      (long-lived)
```

Capture in this ORDER. Bag-and-tag.

## Capturing memory

Tools:
- **Volatility 3** — analyze RAM dumps.
- **LiME** (Linux Memory Extractor).
- **WinPmem** (Windows).
- **AVML** (cloud-friendly).

```bash
# Linux memory dump
sudo avml /evidence/host01.mem
sha256sum /evidence/host01.mem > host01.mem.sha256
```

Don't write the dump to the same disk you're imaging — corruption risk.
Network-mount or USB.

## Disk imaging

```bash
# Bit-for-bit copy
dd if=/dev/sda of=/evidence/host01.img bs=4M conv=noerror,sync status=progress
sha256sum /evidence/host01.img > host01.img.sha256
```

Better: **dc3dd / dcfldd / FTK Imager** — built for forensics, integrity
hashing built-in.

Cloud: snapshot the volume + clone (`aws ec2 create-snapshot`).

NEVER work on the original. Work on a write-blocked copy.

## Chain of custody

Every piece of evidence has a CHAIN OF CUSTODY log:

```
Item:      host01.img
Acquired:  2026-04-12 14:32 UTC
Acquired by: Jane Smith (security)
Hash:      sha256:abc123...
Stored at: vault://evidence/2026-04-12-host01.img
Accessed:
  2026-04-13 10:00 — Jane Smith — review
  2026-04-15 09:30 — Sarah Davis — analysis (witness: Mike)
```

Without this log, evidence is inadmissible in court + worthless in
regulatory proceedings.

## Log analysis — where to look

| Source | What you find |
|---|---|
| Auth logs (`/var/log/auth.log`, AAD logs) | Login attempts, MFA challenges, sudo |
| Web server (`access.log`) | URI patterns, user agents, source IPs |
| App logs | Business events, errors, status codes |
| DB query logs | Suspicious queries, slow queries (DoS), schema reads |
| Audit logs (auditd, AWS CloudTrail, GCP Audit) | API calls, config changes |
| Network flow (VPC Flow Logs, NSG Flow Logs, NetFlow) | Connection patterns, exfil |
| Container / k8s (kube-apiserver audit) | Pod creation, exec, secret reads |
| EDR / XDR (CrowdStrike, SentinelOne) | Process telemetry, file changes |
| DNS logs | C2 callbacks, DGA patterns, exfil over DNS |
| Email gateway | Phishing, attachments, delivery |

Centralize via SIEM (Splunk, Datadog, Elastic, Sumo Logic, Microsoft
Sentinel). Cold storage for long retention (S3 + Glacier + Object Lock for
immutability).

## Common IOC (Indicator of Compromise) categories

- **File hash** (SHA-256 of malicious binary).
- **Filename** + path (e.g. `/tmp/.X11-unix/.x`).
- **Process** (parent → child suspicious chain: `winword.exe` → `powershell.exe`).
- **IP / domain** (C2 server).
- **URL** (drive-by).
- **Registry key** (Windows persistence).
- **User-Agent** (anomaly).
- **Mutex** (malware family marker).

Threat-intel feeds: AlienVault OTX, Mandiant, Crowdstrike, MISP, abuse.ch.

## Threat hunting (proactive)

```
HYPOTHESIS: "An attacker is using PowerShell empire to persist on a workstation."

QUERY (Splunk-flavored):
  index=endpoint EventCode=4688
  | search ParentImage="*powershell.exe"
  | search CommandLine="*-enc*" OR CommandLine="*FromBase64String*"
  | stats count by ComputerName, User

VALIDATE: are findings true positive? known-good?
DOCUMENT: detection turned into alert rule.
LOOP: next hypothesis.
```

Frameworks: TaHiTI (PEAK / SANS), MITRE ATT&CK as hypothesis library.

## Common forensic timeline

```
T-30d   First reconnaissance
T-15d   Phishing email delivered
T-12d   User clicks; initial RAT installed
T-10d   Persistence via scheduled task
T-7d    Lateral movement to file server
T-3d    Credential dump from LSASS
T-1d    Domain admin obtained
T+0     Detection (e.g. ransomware deployment, exfil pattern)
T+0     IR begins
```

Walking BACK from detection: what's the EARLIEST evidence we can find?
Often weeks before. That's where to harden.

## Cloud-specific forensics

- **AWS**: CloudTrail (mandatory), GuardDuty, Detective (case management),
  Inspector (vulns), Macie (data classification).
- **Azure**: Activity Log, Defender for Cloud, Sentinel SIEM.
- **GCP**: Cloud Audit Logs, Security Command Center.
- **Tools**: Cado, Mitiga, Cloud Forensics Utils (Google).

Snapshot rotation for blast radius: take snapshot the moment incident
suspected; analyze the snapshot offline.

## Compromise scope ("blast radius") questions

After identifying compromise:
- **What hosts** are affected? (lateral movement)
- **What accounts** are affected? (credential reuse)
- **What data** was accessed/exfiltrated? (DB / S3 audit logs)
- **What changed**? (config drift, persistence)
- **When did it start**? (earliest IOC date)
- **How did they get in**? (root cause)
- **What was attacker's goal**? (data theft / ransomware / espionage)
- **Did they leave**? (or are they still in?)

Answer ALL before declaring "eradicated."

## Memory + disk analysis tools

| Tool | Use |
|---|---|
| **Volatility 3** | Memory analysis: processes, network, registry, malware |
| **The Sleuth Kit + Autopsy** | Disk forensics, file recovery, timeline |
| **Plaso / log2timeline** | Super-timeline across artifacts |
| **YARA** | Pattern matching for malware signatures |
| **Capa** | Malware behavior identification |
| **Velociraptor** | Endpoint hunting + collection at scale |
| **GRR** | Google's remote forensics framework |
| **Kape** | Targeted collection from Windows hosts |

For Mac forensics: **mac_apt**, **SpotMac**, **OSXAuditor**.

## Evidence preservation — legal angle

If law enforcement may be involved (likely for major breaches):

- Don't modify originals.
- Hash everything; document hashes in lawyer-witnessed format.
- Detail collection procedure.
- Limit who has access to evidence.
- Engage external forensics firm BEFORE you make destructive changes
  (Mandiant, CrowdStrike Services, FireEye).
- Communicate with legal / outside counsel from minute 1.

## When NOT to investigate yourself

Some scenarios you call experts:
- Nation-state attacker (sophisticated APT).
- Suspected insider with destructive intent.
- Regulatory required forensic firm (some compliance needs).
- Lawsuit-likely (preserve attorney-client privilege).

Your internal team handles detection + containment; external handles deep
forensics + courts.

## Anti-patterns

- **Log into the suspected-compromised host** — destroys volatile evidence,
  alerts attacker.
- **Reboot to "clear it"** — destroys RAM evidence.
- **Run AV scan on production data** — quarantine destroys evidence.
- **No log retention** — investigation hits wall when logs rolled.
- **Logs only in the compromised system** — attacker tampers/deletes.
- **No central time sync** — logs across hosts incoherent.
- **Working on originals** — corruption + chain-of-custody death.
- **Skipping the post-mortem** — losses repeat.

## Validation

- [ ] Centralized logging in place (90+ days hot, 7+ years cold).
- [ ] Logs immutable / append-only.
- [ ] NTP / time sync verified across infrastructure.
- [ ] Jump bag prepared (forensic tools, USB write-blocker, evidence bags).
- [ ] Retainer with external forensics firm (for SEV-1).
- [ ] Chain-of-custody template in IR runbook.
- [ ] Last tabletop exercise included forensics steps.
- [ ] Threat hunting program with hypothesis backlog + actionable findings.
