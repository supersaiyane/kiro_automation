---
id: supply_chain_sbom_slsa
version: 1.0.0
owners: [security_engineer, devops_engineer]
tags: [supply-chain, sbom, slsa, sigstore, provenance, dependencies]
when_to_use: |
  Any system that pulls third-party code (which is all of them).
  Apply BEFORE you're a SolarWinds / log4shell / xz case study.
  Sequence: SBOM first (visibility), then signing (integrity), then
  SLSA levels (provenance), then policy enforcement at admission.
inputs:
  - build_pipeline, container_registries, artifact_repos
outputs:
  - "supply_chain_controls: SBOM per artifact + signed provenance + policy enforcement at deploy"
---

# Software Supply Chain Security (SBOM + SLSA + Sigstore)

> Your "code" is 5% you and 95% transitive dependencies. Treat the
> 95% as untrusted until you have a name, a version, a hash, and a
> signature for every byte.

## The threat model (post-SolarWinds, post-log4shell, post-xz)

Attack surface, in order of frequency observed in the wild:

1. **Compromised dependency** — typosquat, account takeover of a
   maintainer, deliberate backdoor (xz-utils 2024).
2. **Compromised build system** — attacker injects code between
   `git pull` and `docker push`. SolarWinds was this.
3. **Compromised registry** — image tag points to a different SHA
   than expected.
4. **Compromised base image** — `FROM ubuntu:latest` is a moving
   target you don't control.
5. **Insider threat** — privileged dev pushes signed-but-malicious code.

You CANNOT defend against #1-5 with code review alone. You need
machine-verifiable provenance.

## The four-layer stack

```
Layer 4: POLICY    │ Admission controller refuses unsigned/non-SLSA images
                   │ (Kyverno, OPA Gatekeeper, Sigstore policy-controller)
                   │
Layer 3: PROVENANCE│ SLSA attestations — WHO built WHAT from WHICH source
                   │ (slsa-github-generator, in-toto attestations)
                   │
Layer 2: SIGNATURES│ Every artifact signed (Sigstore cosign, keyless OIDC)
                   │
Layer 1: SBOM      │ Every artifact has a bill of materials
                   │ (Syft, CycloneDX, SPDX 2.3)
```

Build bottom-up; you cannot enforce policy on data you don't have.

## Layer 1 — SBOM (the inventory)

**Format**: CycloneDX or SPDX 2.3. Pick one; CycloneDX is the more
common in 2025 vuln tooling.

**Generation** (at build time, NOT at scan time):

```bash
# Syft — generate SBOM from container image
syft ghcr.io/your-org/your-app:1.2.3 -o cyclonedx-json > sbom.json

# Or from source
syft dir:. -o spdx-json > sbom.json
```

**Storage**:
- Attach the SBOM to the artifact via OCI referrer (cosign attach
  sbom) — not a separate registry the deploy pipeline might forget.
- Keep one SBOM PER (artifact, version). Never overwrite.

**What an SBOM unlocks**:
- "Are we exposed to CVE-2025-XYZ?" → query SBOMs, not laptops.
- "What's the license of every transitive dep?" → SBOM query.
- "Who is shipping log4j-core 2.14?" → SBOM query, not git grep.

## Layer 2 — Signing (Sigstore cosign + keyless)

The big win in 2025 is **keyless signing** via OIDC:

```bash
# Sign on GitHub Actions (token-bound identity, no long-lived keys)
cosign sign --yes ghcr.io/your-org/your-app:1.2.3

# Verify at deploy
cosign verify ghcr.io/your-org/your-app:1.2.3 \
  --certificate-identity-regexp '^https://github.com/your-org/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

The certificate identity binds the signature to a specific
workflow on a specific repo. An attacker who pops a developer
laptop CANNOT mint a valid signature; they'd have to compromise
the GitHub Actions runner identity.

**Cosign also signs**: SBOMs, SLSA provenance, container images,
arbitrary blobs, Helm charts.

## Layer 3 — SLSA provenance (where did this come from?)

SLSA (Supply-chain Levels for Software Artifacts) defines maturity
levels for build provenance:

| Level | Requirement | Practically means |
|---|---|---|
| 1 | Build process documented + provenance generated | A `cosign attest` exists |
| 2 | Hosted build service + tamper-resistant provenance | GitHub Actions / GCB / Tekton, signed provenance |
| 3 | Hardened builds, non-falsifiable provenance | Isolated runners, no maintainer override |
| 4 | Two-party review + hermetic builds | Reproducible bit-for-bit, very few projects ship this |

**Pragmatic target for most teams: SLSA 3.** Use
`slsa-github-generator` if on GHA. Provenance contains:
- The exact source commit SHA.
- The exact builder image + version.
- The build parameters.
- A signed attestation tying all of the above to the artifact digest.

A consumer with provenance can answer "did this binary come from
commit X built by builder Y?" — purely from cryptographic evidence.

## Layer 4 — Policy enforcement (where it pays off)

The SBOM, signature, and provenance are worthless if your cluster
runs unsigned images. Enforce at admission:

```yaml
# Kyverno policy — refuse unsigned images from your registry
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-cosign-sig
spec:
  validationFailureAction: Enforce
  rules:
    - name: verify-sig
      match:
        any:
          - resources:
              kinds: [Pod]
      verifyImages:
        - imageReferences: ["ghcr.io/your-org/*"]
          attestors:
            - entries:
                - keyless:
                    subject: "https://github.com/your-org/*/.github/workflows/release.yml@*"
                    issuer: "https://token.actions.githubusercontent.com"
```

Tighten in stages:
1. Audit mode (warn only). Watch your own deploys break first.
2. Enforce only for the highest-risk namespaces.
3. Enforce across the cluster.

## Continuous vulnerability surveillance

Once you have SBOMs at rest:

```bash
# Grype scans SBOM against the vuln DB; no rebuild needed
grype sbom:sbom.json --fail-on high

# Dependency-Track ingests SBOMs and re-scans nightly
# (much smarter than scan-at-build-only — vulns are found AFTER ship)
```

Daily SBOM re-scan is what catches log4shell-style mass disclosures.
A "we scanned at build time" pipeline catches nothing after merge.

## Anti-patterns

- **"Our SCA tool covers this."** Snyk / Dependabot scan
  SOURCE, not the built artifact. They miss anything that
  enters during build (typosquatted build deps, compromised base image).
- **Long-lived signing keys on a CI server.** Use keyless OIDC.
- **Latest tag in production.** `:latest` is a moving signature
  target. Pin by digest (`@sha256:...`) in deploy manifests.
- **SBOM generated at scan time, not build time.** The build is
  the only moment when you can SEE every transitive dep with
  certainty. Scanning a deployed image post-hoc misses build-only deps.
- **One mega-SBOM for the whole org.** SBOMs are per (artifact,
  version). Otherwise diffing is impossible.
- **Trusting "official" base images blindly.** Even `node:20-slim`
  has a CVE backlog. Distroless or chainguard images cut this by
  90%+.

## The 30-day adoption sequence

Week 1 — Generate. Add Syft to one pipeline. Push SBOMs as OCI
referrers. Don't enforce anything yet.

Week 2 — Sign. Add cosign keyless signing. Verify locally,
not in admission.

Week 3 — Attest. Add SLSA provenance via slsa-github-generator.
Verify locally.

Week 4 — Enforce (audit mode). Deploy Kyverno / policy-controller
in audit. Look at the warnings list; expect 50+ per day for the
first week. Fix the violators one repo at a time.

Month 2 — Switch to enforce mode for one prod namespace. Roll
forward namespace by namespace.

## Validation that supply chain is real

- [ ] `cosign verify ghcr.io/our-org/our-app:1.2.3` returns OK
      with the expected GHA workflow identity.
- [ ] An unsigned image FAILS to deploy to a prod namespace.
- [ ] `grype sbom:<our-sbom>.json` runs in under 30 seconds
      and produces a vuln list.
- [ ] When a new CVE drops, you can answer "are we exposed?" in
      < 5 minutes using your SBOM store.
- [ ] An attacker who compromises one developer's laptop CANNOT
      ship a malicious image because they can't mint a valid GHA
      workflow signature.
