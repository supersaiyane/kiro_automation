---
id: stride_threat_modeling
version: 1.0.0
owners: [architect, security_engineer]
tags: [security, threat-model, stride, owasp, design-review]
when_to_use: |
  Designing or reviewing a feature that handles authentication, user
  data, payments, file uploads, or any external interface.
inputs:
  - system_dfd: components + trust boundaries + data flows
outputs:
  - threat_table: STRIDE category per asset + mitigation per threat
---

# STRIDE Threat Modeling

Six categories, applied to every component:

| Letter | Threat                   | Property violated    |
|--------|--------------------------|----------------------|
| S      | Spoofing                 | Authentication       |
| T      | Tampering                | Integrity            |
| R      | Repudiation              | Non-repudiation      |
| I      | Information Disclosure   | Confidentiality      |
| D      | Denial of Service        | Availability         |
| E      | Elevation of Privilege   | Authorization        |

**Method**
1. Draw a Data Flow Diagram with trust boundaries (the moment data
   crosses a boundary is the only place threats can enter).
2. Iterate STRIDE per element type: processes (all six), data stores
   (T,R,I,D), data flows (T,I,D), external entities (S,R).
3. For every credible threat, record asset, attack vector, severity,
   mitigation.
4. Validate at least one mitigation per critical threat is enforced
   in code, not just policy.

**Anti-patterns**
- Modeling the whole system at once; do it per feature.
- Stopping at "we use HTTPS"; HTTPS doesn't address T over the trust
  boundary inside the cluster.
- Logging the mitigation but never testing it.
