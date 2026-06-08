---
id: owasp_top10_review
version: 1.0.0
owners: [security_engineer]
tags: [security, owasp, code-review, vulnerability]
when_to_use: |
  Reviewing the backend or frontend code produced by the SR_ENGs before
  release. The output is the SEC report consumed by the review_gate.
inputs:
  - code_diff_or_artifact: code under review
outputs:
  - findings: severity-tagged list (CRITICAL_FINDINGS, HIGH_FINDINGS)
---

# OWASP Top 10 Review (2021 edition)

Walk the code with this checklist. For each match, classify severity.

| # | Category                       | What to look for in code |
|---|--------------------------------|--------------------------|
| 1 | Broken Access Control           | Missing authz on endpoints; IDOR (object id from URL with no ownership check) |
| 2 | Cryptographic Failures          | Plaintext secrets, MD5/SHA1 for passwords, weak TLS settings |
| 3 | Injection                       | String concatenation into SQL, shell, LDAP, NoSQL queries |
| 4 | Insecure Design                 | Auth flows that lack rate limiting, recovery paths weaker than primary |
| 5 | Security Misconfiguration       | Verbose error responses to clients; default creds; open CORS |
| 6 | Vulnerable Components           | Pinned-but-outdated deps with known CVEs |
| 7 | Identification & Auth Failures  | Predictable session IDs, no MFA option, no logout that invalidates |
| 8 | Software & Data Integrity       | Unsigned deserialization; CI/CD without provenance |
| 9 | Logging & Monitoring Failures   | Auth events not logged; PII in logs |
| 10| SSRF                            | User-supplied URLs fetched by the server with no allowlist |

**Severity reporting**

- `CRITICAL_FINDINGS:` — exploitable now, with direct impact. Blocks release.
- `HIGH_FINDINGS:` — likely exploitable, or impact is high. Fix before release.
- Below: log as suggestions; don't block.

**Anti-patterns**
- Grepping for keywords instead of reading auth boundaries.
- Reporting a long list of LOW items and burying the one CRITICAL.
- Letting "we have HTTPS" answer most categories — it doesn't.
