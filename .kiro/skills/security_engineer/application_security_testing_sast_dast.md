---
id: application_security_testing_sast_dast
version: 1.0.0
owners: [security_engineer, qa_engineer, devops_engineer]
tags: [appsec, sast, dast, iast, fuzzing, ci-security, sca]
when_to_use: |
  Wiring security tests into CI. SAST catches code-level vulns, DAST
  catches runtime + config vulns, IAST catches both at the cost of an
  agent in QA. SCA catches dependency CVEs. Each is necessary; together
  they form the AppSec testing baseline.
inputs:
  - source_repo, ci_pipeline, deployment_topology
outputs:
  - "appsec_pipeline: SAST + SCA + DAST + IAST integration + severity policy + triage workflow"
---

# Application Security Testing — SAST, DAST, IAST, SCA, Fuzzing

> Defense in depth at the testing layer: every commit, every deploy,
> every dependency, every payload shape. No single tool catches
> everything; pick a portfolio.

## Tool taxonomy

| Class | When | Catches | Speed | False-positive rate |
|---|---|---|---|---|
| **SAST** | Pre-merge (CI) | Code-level: injection, hard-coded secrets, unsafe deserialization | Minutes | High |
| **SCA** | Pre-merge + nightly | Known-vulnerable dependencies (CVE) | Seconds | Low |
| **DAST** | Pre-deploy / staging | Runtime: auth bypass, IDOR, XSS, misconfig | Hours | Medium |
| **IAST** | Inside running app (QA env) | Both — sees code + traffic | Real-time | Low |
| **Fuzzing** | Continuous / OSS-Fuzz | Memory safety, parser bugs, crashes | Days/weeks | Very low |
| **Container scan** | Pre-push to registry | OS + lang package CVEs in images | Minutes | Low |
| **IaC scan** | Pre-merge | Terraform / k8s misconfig | Seconds | Low |

## SAST — gate on changed code only

Don't fail PRs on legacy findings; gate ONLY on new findings in changed lines.

```yaml
# .github/workflows/sast.yml
- uses: github/codeql-action/init@v3
  with: { languages: 'python, javascript' }
- uses: github/codeql-action/analyze@v3
  with: { upload: true }
```

Other tools: SonarQube, Semgrep (great for custom rules), Checkmarx, Veracode.

**Rule of thumb**:
- Open-source / startup: Semgrep + GitHub CodeQL (free for open repos).
- Mature org: Semgrep Cloud OR Snyk Code, plus CodeQL on critical repos.

## SCA — the most-bang-for-buck control

Dependency vulnerabilities cause more breaches than zero-days (Log4Shell,
Equifax). Tools:

- **Dependabot** (GitHub native) — basic, free.
- **Snyk** — broader DB, fixable-PR generation.
- **Renovate** — bumps deps proactively even when not a CVE.
- **OSV-Scanner** (Google) — open-source, hits the OSV.dev DB.
- **Trivy** — also does container + IaC.

Run SCA on EVERY PR. Block on Critical CVEs in production-bound paths.

## DAST — black-box testing of running apps

Tools: OWASP ZAP, Burp Suite (manual), Nuclei (YAML-based templates),
StackHawk (CI-friendly).

```yaml
# Run DAST against staging after deploy
- name: ZAP baseline scan
  uses: zaproxy/action-baseline@v0.10.0
  with: { target: 'https://staging.example.com' }
```

DAST catches things SAST can't:
- Authentication misconfigurations
- IDOR (Indirect Object References)
- Missing security headers (CSP, HSTS, X-Frame-Options)
- Server misconfigurations exposing /admin
- Insecure HTTP redirects

DAST has high false-positive rate on dynamic sites; tune the baseline.

## IAST — agent in the running app

Tools: Contrast Security, Veracode IAST, Datadog ASM.

The agent watches code execution + HTTP traffic together. When a request
arrives, the agent traces what code runs; if user input flows to a sink
(SQL query, file write, exec) without sanitization → vulnerability with
exact stack trace.

Pros: very low FP, exact pinpoint.
Cons: requires agent install; impacts perf 5-15%; commercial mostly.

Default: NOT for every workload. Use on the most-exposed services.

## Fuzzing — for parsers + serializers

Tools: AFL++, libFuzzer, Atheris (Python), Cargo-fuzz (Rust), OSS-Fuzz
(Google-hosted, free for OSS).

```c
// libFuzzer harness
int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
    parse_json(data, size);  // crash here = bug
    return 0;
}
```

Best for: JSON/XML/protobuf parsers, file format handlers, network protocol
implementations, ANY user-controlled string parsing.

## Container + IaC scanning

```yaml
# Trivy on every PR
- run: trivy fs --severity HIGH,CRITICAL .

# Trivy on built images, fail build on critical
- run: trivy image --exit-code 1 --severity CRITICAL ghcr.io/org/app:${{ github.sha }}
```

Catches:
- Base image CVEs (use distroless / Chainguard / Wolfi to reduce)
- IaC misconfig (S3 buckets public, security groups 0.0.0.0/0)
- Secrets committed to git

## Severity policy — what blocks vs informs

| Severity | SAST | SCA | DAST | Action |
|---|---|---|---|---|
| Critical | Block merge | Block merge | Block deploy | PAGE |
| High | Block merge | Block if no patch in 7d | Block deploy | Ticket P1 |
| Medium | Warn + ticket | Warn + ticket | Warn + ticket | Backlog |
| Low | Track | Track | Track | Periodic review |

ENFORCEMENT must align with patch availability. Blocking on a Critical with
no upstream patch causes work-arounds; have a documented exception process.

## Triage workflow

```
1. Tool flags finding → auto-ticket with file:line + CWE
2. Auto-assign to file CODEOWNER
3. Triage SLO: critical 4h, high 24h, medium 7d
4. Each finding: fix / suppress (with justification) / accept-risk (sign-off)
5. Suppression rules in code (e.g. `# noqa: B101` with comment-why)
6. Quarterly review of accepted risks
```

Tools that help: GitHub Code Scanning, Snyk, Defect Dojo (open-source
aggregator), ASOC platforms (Cycode, Apiiro).

## Bug bounty + responsible disclosure

For mature orgs: a public bug bounty (HackerOne, Bugcrowd, Intigriti) catches
what internal AppSec misses. Pre-requisites:

- Triage capacity (ratio: 1 AppSec FTE per 200 reports/month).
- A safe-harbor policy.
- A response SLO (acknowledge < 24h, decision < 7d).
- Payouts that match scope value.

Don't launch a bounty before internal AppSec is mature; you'll drown in
basics.

## Anti-patterns

- **One tool blocks merge, another only warns.** Inconsistent gate → devs
  ignore the warning tool. Apply consistent severity policies.
- **Scanning in production only.** Fix at the source (PR), not after deploy.
- **No suppression mechanism in code.** Devs work around the scanner instead
  of marking false positives explicitly.
- **Block on Critical without checking patch availability.** Causes hot-fix
  hell or shadow workarounds.
- **No baseline.** First scan finds 500 issues; nobody acts; tool becomes
  noise. Establish baseline + only enforce on NEW findings.
- **Skipping container/IaC scans because "we already do SAST".** Different
  attack surfaces.

## Validation

- [ ] SAST runs on every PR with CodeQL or Semgrep.
- [ ] SCA runs on every PR, dependency PRs auto-opened.
- [ ] DAST runs after each staging deploy.
- [ ] Container scan blocks pushes with Critical CVEs.
- [ ] Severity policy is documented and consistently applied.
- [ ] Triage SLOs met for last quarter.
- [ ] At least one critical-severity finding in the last 90 days went
      from detection → fix in under SLO.
