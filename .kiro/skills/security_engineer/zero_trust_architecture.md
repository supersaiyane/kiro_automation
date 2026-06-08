---
id: zero_trust_architecture
version: 1.0.0
owners: [security_engineer, architect]
tags: [zero-trust, nist-800-207, identity, authorization, network-security]
when_to_use: |
  Designing or auditing any system where the perimeter model is
  insufficient — cloud-native, multi-tenant SaaS, remote workforce,
  inter-service mesh. Apply BEFORE the first prod deploy; retrofitting
  zero-trust into a perimeter design is multi-quarter work.
inputs:
  - asset_inventory, identity_sources, data_classification
outputs:
  - "zero_trust_design: per-resource access policies + enforcement points + continuous-verification telemetry"
---

# Zero Trust Architecture (NIST 800-207)

> **Never trust, always verify.** No network location is inherently
> trusted. Every access request is authenticated + authorized +
> encrypted, regardless of where it came from.

## The seven tenets (NIST SP 800-207)

1. **All data sources and computing services are resources.** Personal
   devices accessing your data are resources too. There is no "inside."
2. **All communication is secured regardless of network location.**
   TLS everywhere, including intra-datacenter.
3. **Access to individual enterprise resources is granted on a
   per-session basis.** No long-lived "I'm on the VPN, I'm good"
   sessions.
4. **Access is determined by dynamic policy** — identity, device
   posture, behavior, request context. Not just username/password.
5. **Asset integrity + security posture monitored.** The device asking
   for access has its compliance state checked at every request.
6. **All authentication + authorization is dynamic, strictly
   enforced before access.** No implicit trust based on first login.
7. **Continuous collection of telemetry** about asset and network
   state used to improve the policy.

## Components (the NIST reference architecture)

```
┌──────────────┐  request  ┌──────────────┐
│    Subject   │ ────────► │     PEP      │  (Policy Enforcement Point)
│ (user/device)│           │  inline guard│  enforces every request
└──────────────┘           └──────┬───────┘
                                  │ consults
                                  ▼
                          ┌──────────────┐
                          │     PDP      │  (Policy Decision Point)
                          │ policy engine│  identity + posture +
                          └──────┬───────┘  context → ALLOW/DENY
                                  │
                          ┌───────┴────────┐
                          ▼                ▼
                      [Identity]      [Device posture]
                      provider        attestation
                          │                │
                          └────[ Threat intel + behavior analytics ]
```

- **PEP** sits in front of every resource. Cloud-native: service mesh
  sidecar (Istio, Linkerd), API gateway, identity-aware proxy.
- **PDP** evaluates policies. Use OPA / Cedar / a homegrown engine.
- **Telemetry** flows back continuously; risk score per
  (user, device, time) is recomputed at every request.

## What changes in your design

### Identity ≠ network address
The user is the principal. The device is a co-principal (posture
matters). The network address is just metadata.

### Per-request authorization
The PEP authorizes **every** call against the PDP. Long-lived sessions
DO still exist (refresh tokens with short access tokens), but each
access token check goes through the PDP.

### Mutual TLS for service-to-service
Every service identifies every other service via mTLS certificates
issued by a workload-identity system (SPIFFE, IRSA, GKE workload
identity). No service trusts another by network address.

### Microsegmentation
Network reachability is collapsed to "only the explicit policy
allows it." Default-deny + explicit allow per (source service,
destination service, port, protocol).

### Continuous device posture
Device health (OS version, EDR running, disk encryption, screen lock)
is checked at each request. Non-compliant devices fail the request
even with valid credentials.

## Implementation paths (pragmatic)

### For a small team / new system
1. **Identity-aware proxy** in front of every internal app
   (BeyondCorp / Pomerium / Cloudflare Access). Removes the VPN.
2. **mTLS via a service mesh** for internal traffic (Istio/Linkerd).
3. **Workload identity** for cloud services (IRSA on AWS, Workload
   Identity on GCP). No long-lived API keys.
4. **OPA gatekeeper** for k8s + admission control on resource access.
5. **MFA on every human login** (WebAuthn / passkeys preferred).

### For an existing perimeter org
1. **Inventory + classify** resources by data sensitivity.
2. **Identity-aware proxy** in front of crown-jewel resources first.
3. **Eliminate the VPN's "everything else is trusted"** model
   incrementally — service by service.
4. **Adopt SSO + MFA universally**; remove direct LDAP / local auth.
5. **Monitor and enforce device posture** for crown-jewel access.

This is multi-quarter, multi-year work. Tier by data sensitivity.

## Anti-patterns

- **"VPN = zero trust"** — a VPN is the OPPOSITE of zero trust. It
  grants implicit network-level trust.
- **Long-lived API keys** as service identity. Use short-lived
  workload-identity tokens.
- **Device posture as a one-time check at enrollment.** Posture
  changes; check continuously.
- **MFA only for admin accounts.** Lateral movement starts from a
  compromised non-admin account. MFA everyone.
- **One mega-policy that covers everything.** Policies should be
  per-resource, per-role, version-controlled.
- **"We bought a zero-trust product, so we're done."** Zero trust is
  an architecture, not a product. The architecture must permeate
  every system.

## Validation that zero-trust is real

- [ ] You can DISCONNECT THE VPN and most services still work via the
      identity-aware proxy.
- [ ] An attacker on the corporate Wi-Fi has the SAME access as one
      on the public internet (none — both authenticate).
- [ ] Service-to-service compromise is contained: a popped service
      can't reach another service it doesn't have explicit policy for.
- [ ] Telemetry shows per-request policy decisions, queryable by
      (user × resource × time).
- [ ] Device posture failure denies access in <60 seconds of
      noncompliance.
