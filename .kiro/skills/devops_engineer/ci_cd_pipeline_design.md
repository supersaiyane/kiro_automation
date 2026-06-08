---
id: ci_cd_pipeline_design
version: 1.0.0
owners: [devops_engineer, backend_lead]
tags: [ci-cd, pipeline, github-actions, deploy, gates]
when_to_use: |
  Setting up a new service's CI/CD or auditing an existing one.
  Pipeline is the contract between "merged" and "in production." Get
  the gates right or you'll either ship bugs fast or block on
  ceremony forever.
inputs:
  - service_repo + deploy_target
outputs:
  - pipeline_yaml: PR-time + main-merge + tag-release stages
---

# CI/CD Pipeline Design

## The three pipelines, not one

Most teams crash everything into one workflow. Split:

1. **PR pipeline** — fast feedback for the author. Target: <8 min p95.
2. **Main pipeline** — runs on merge to main; builds the canonical
   artifact; deploys to staging.
3. **Release pipeline** — runs on tag push; promotes the staging
   artifact to production after gates.

Don't conflate. The PR doesn't need to build a multi-arch image; the
release doesn't need to re-run the linter.

## PR pipeline — the eight things that matter

In rough order of speed-to-feedback:

1. **Lint / format check** (<30s). Ruff, Black, ESLint, Prettier. Fail
   fast on hygiene.
2. **Type check** (<2 min). mypy, tsc. Fail before tests run.
3. **Unit tests** (<3 min). Parallelized by file/package.
4. **Build** (<3 min). Compile, bundle, or image-build (single-arch
   for PR).
5. **Integration tests** (<5 min, optional). Spin up dependencies via
   docker-compose; the slowest tests.
6. **Security scans** (run in parallel with tests; non-blocking on
   warnings):
   - **SAST**: `bandit`, `semgrep`. Block on CRITICAL.
   - **Dependency scan**: `pip-audit`, `npm audit`. Block on
     CRITICAL CVEs in production deps.
   - **Secret scan**: `gitleaks`. Block on any match.
7. **Coverage delta**. Block on coverage drop >2% absolute.
8. **Performance budget check** (FE only). Lighthouse CI; block on
   p75 LCP / CLS regression.

**All required checks must finish in <10 min.** Beyond that, authors
context-switch and review quality drops.

## Main pipeline — what changes

- Multi-arch image build (`buildx`).
- Container image scan (Trivy, Grype). Block on CRITICAL.
- SBOM generation (`syft`). Attached to the image.
- Image signing (`cosign`).
- Push to registry with both `main-<sha>` and `main-latest` tags.
- Deploy to staging.
- Smoke tests against staging.
- (Optional) Automatic rollback if staging healthcheck fails.

## Release pipeline — gates that matter

Triggers on a tag push (e.g. `v1.4.0`). Gates in order:

1. **Tag must be on main** (no off-branch tags shipping).
2. **All checks on the commit must be green** (re-validate, don't
   trust the merge-time result alone).
3. **Image must exist + be signed**.
4. **Staging soak**: image must have been on staging for ≥N minutes
   without incident.
5. **Change-management gate** (CAB / approval if regulated).
6. **Manual approval** for production (GitHub Environments approval
   button).
7. **Progressive rollout**: 5% → 25% → 50% → 100%, with auto-pause on
   SLO breach.
8. **Rollback runbook linked** in the deploy message.

## Caching — the secret to a fast pipeline

- **Action cache**: `~/.cache/pip`, `~/.npm`, `~/.cargo` keyed by
  lockfile hash. Restores in <5 s.
- **Layer cache**: BuildKit's `--cache-from` + remote cache (registry,
  S3). Cuts image build 80%.
- **Test cache**: `pytest --cache-show` for re-run, or test-impact
  analysis (only re-run tests for changed files). Aggressive — verify
  on main with full run.
- **Avoid global caches** that grow unbounded. Cache key must include
  lock-file hash; without it, you cache stale.

## Pipeline-as-code rules

- **Pinned action versions** (commit SHA, not `@v1`). Floating tags
  get hijacked.
- **Least-privilege tokens**. The CI's GH token: minimum scope per
  job. No `secrets.GITHUB_TOKEN` with admin perms.
- **No secrets in workflow files**. Reference org-level secrets;
  rotation lives elsewhere.
- **Reusable workflows / composite actions** to deduplicate. Don't
  copy-paste 8 jobs across 12 repos.
- **Workflow concurrency** controlled — `concurrency: ci-${{ github.ref }}`
  to cancel obsolete runs.

## Failure handling

- Every failure has a stable artifact (logs, screenshots, junit) that
  outlives the workflow run.
- Flaky tests are tagged and quarantined; not retried on green to
  paper over flakiness.
- Auto-retry only for known-transient failures (network, registry
  pull). Max 1 retry.

## Anti-patterns

- 45-minute PR pipelines. Authors disengage; quality drops.
- One mega-workflow for PR + main + release. Cognitive overhead +
  branching logic everywhere.
- "Skip CI for docs" toggle that becomes "skip CI when in a hurry".
- Tests that touch production data. CI must be hermetic.
- Deploys triggered by branch push instead of tag push. Loses the
  artifact-identity property of "exactly this tag is in prod."
- No artifact retention. Build #18 of yesterday is gone; you can't
  re-deploy or audit.
- Pipelines that depend on the developer's local machine state
  (custom Docker images, secrets in env).
- Auto-merge on green. Removes the human gate; "green" doesn't mean
  "right."
