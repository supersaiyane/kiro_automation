---
id: platform_engineering_idp
version: 1.0.0
owners: [devops_engineer, sre, architect]
tags: [platform-engineering, idp, backstage, golden-path, developer-experience]
when_to_use: |
  Engineering org has > 30 devs across > 5 teams, OR cognitive load
  on devs (k8s + CI + observability + secrets + IAM + ...) is the
  bottleneck. Platform engineering builds the "internal product"
  that other engineers use to ship faster.
inputs:
  - team_topology, current_dev_pain_points, time_to_first_deploy
outputs:
  - "idp_design: golden paths + platform APIs + self-service surface + ownership model"
---

# Platform Engineering — IDP, Golden Paths, Team Topologies

> Every engineer doing their own k8s + Terraform + CI + secrets is
> spending 60% of their time on undifferentiated infra. Platform
> engineering builds the "internal product" — golden paths,
> templates, and abstractions — so the other 60% goes to features.

## The problem in one chart

```
                       BEFORE platform                    AFTER platform
Time to first deploy   2-3 weeks (figure out k8s, IAM)    < 1 day (golden path)
Cognitive load         Every dev learns 12 tools          Devs use 2-3 platform APIs
On-call quality        Each team reinvents alerting       Shared alerting baseline
Compliance             Per-team interpretation            Built into the platform
Cost of new service    1-2 weeks of plumbing              1 PR
```

The numbers are real; CNCF + DevOps Research surveys confirm 30-50%
lead time reductions in mature platform orgs.

## Team Topologies (Skelton + Pais)

Four team patterns, only ONE builds the platform:

- **Stream-aligned team** — owns a value stream / product. The
  CUSTOMERS of the platform.
- **Enabling team** — short-lived; helps a stream team adopt a
  practice. Coaching, not building.
- **Complicated-subsystem team** — specialists; owns one hard
  domain (e.g., search infra).
- **Platform team** — builds the internal product. Their customers
  are other engineers.

The platform team is a PRODUCT team. They have:
- A product manager (or PM-discipline rotated).
- A roadmap based on developer pain points.
- Internal NPS, ticket SLAs, satisfaction surveys.
- Versioned APIs they don't break casually.

If the platform team treats its outputs as "infra projects," they
build things engineers won't use. Treat it as product.

## Golden paths — the killer feature

A golden path is the "happy path" template for a common task. For
"create a new microservice in our stack":

```
$ idpctl new service --type=api --owner=team-alpha --name=billing
✓ Generated app skeleton with our standards (logging, metrics, tracing)
✓ Created GitHub repo with CODEOWNERS
✓ Wired CI/CD (build, test, sign, deploy to staging)
✓ Provisioned a Postgres DB with credentials in Vault
✓ Registered service in service catalog
✓ Created Datadog dashboard + on-call rotation
✓ Created PagerDuty service
✓ Service is deployed to staging
✓ Open the PR: https://github.com/org/billing/pull/1

Time elapsed: 4 minutes 12 seconds.
```

Behind the scenes: cookiecutter / Backstage scaffolder, Terraform
modules, GitOps repo updates, CI templates. The dev sees one command.

**Golden paths are NOT mandatory.** They are "the easiest correct
thing." If your platform forces use, devs work around it. Make the
golden path the path of least resistance and engineers self-select.

## The IDP — Internal Developer Platform

A real IDP exposes:

### 1. A service catalog
Backstage (most common, CNCF), Cortex, OpsLevel, or homegrown.
Lists every service + owner + on-call + dependencies + docs +
metrics + cost. The "Yellow Pages" of engineering.

### 2. A self-service surface
- Web UI (Backstage scaffolder, Port).
- CLI (idpctl, kratix).
- Pipelines / templates.

Engineers should not need to learn Terraform to provision a database.
They click "Postgres", pick size and region, get a connection string
in Vault.

### 3. A platform API
The underlying control plane (Kubernetes CRDs, Crossplane Compositions,
Terraform modules called via Atlantis). Standardized so the UI/CLI
can be replaced without rebuilding.

### 4. Observability built in
New service → metrics, logs, traces, dashboards, SLOs, alerts auto-wired.
Engineers don't write their own dashboard from scratch each time.

### 5. Compliance built in
Security policies, IAM defaults, network policies, secret access.
The platform makes the COMPLIANT thing the EASY thing.

## Crossplane vs Backstage vs Argo vs Terraform — they don't compete

| Tool | Role |
|---|---|
| Backstage | The portal — service catalog + scaffolder UI |
| Crossplane | The control plane — k8s-native cloud resource composition |
| Argo CD | The reconciler — git → cluster |
| Terraform | The lower-level provisioner — when Crossplane isn't enough |
| OpenFeature | Standard for flags inside the platform |
| OpenTelemetry | Standard for telemetry inside the platform |

You typically use all of them. The platform team's job is to make
the seams invisible.

## What the platform team builds vs buys

| Build | Buy / use OSS |
|---|---|
| Golden path templates for YOUR stack | Backstage core |
| Service catalog data ingestion | Service catalog framework |
| Compliance policies (your specifics) | OPA, Kyverno |
| Custom CRDs for unique business needs | k8s ecosystem |
| Internal CLI (idpctl) | Crossplane / Terraform modules |

Rule: build the parts that ENCODE YOUR ORG. Buy/use the parts that
are commodity (DAG runners, log shippers, ingress controllers).

## Measuring the platform — DORA + flow metrics

A platform team's success is measured by the STREAM TEAMS using it:

- **Deploy frequency** (DORA) — should go UP after platform adoption.
- **Lead time for changes** (DORA) — DOWN.
- **Change failure rate** (DORA) — DOWN (golden path bakes in safety).
- **MTTR** (DORA) — DOWN (built-in observability).
- **Developer NPS** — quarterly survey of platform satisfaction.
- **Time-to-first-deploy** for a new hire — DOWN.

If the platform team can't show these moving, the platform isn't
delivering. Be ready to cut features that don't get used.

## The cognitive load principle

Skelton + Pais: a stream team has a cognitive load budget. Your
job as platform is to keep it within budget. Things that bust the
budget:

- Onboarding a new language stack with no platform support.
- A service that requires 5 dashboards to operate.
- An incident runbook that's 40 pages.

When a team is overloaded, the answer is RARELY "more discipline";
it's "absorb the complexity into the platform."

## Anti-patterns

- **Platform team builds in isolation.** No customer feedback →
  unused features. Embed PMs, run office hours, prioritize tickets.
- **Mandatory platform with no opt-out.** Engineers find creative
  workarounds. Make the golden path the easy path; let edge cases
  diverge.
- **"We are the gatekeepers."** Platform that requires platform-team
  approval for every change becomes the bottleneck the platform was
  supposed to remove.
- **Building a platform with one customer.** A "platform" used by
  one team is a project, not a platform. Either generalize or
  reclassify.
- **No versioning of platform APIs.** Breaking changes propagate
  to every consumer; trust evaporates.
- **Treating Backstage as the platform.** Backstage is the portal.
  The platform is the dozens of automations behind it.

## Adoption sequence (12 month plan for a 50-eng org)

Q1 — Inventory pain. Interview 10 engineers; rank top 5 frictions.
     Build the service catalog (basic). Measure baseline DORA.

Q2 — Ship golden path #1 for the most common case (new microservice).
     One repo template + auto-provisioning. Onboard 2 teams as
     design partners.

Q3 — Ship golden path #2 (Postgres + Redis self-service). Migrate
     existing services in scope.

Q4 — Observability built-in (auto SLOs, dashboards). Compliance
     policies in CI. Measure DORA delta vs baseline; goal: ≥ 30%
     lead time improvement.

## Validation that the platform pays off

- [ ] Time-to-first-deploy for a new service is < 1 day for stream
      teams (measured, not guessed).
- [ ] DORA metrics improved measurably since platform launch.
- [ ] Developer NPS is > 30 (good) or > 50 (great).
- [ ] Platform API has documented versioning; no breaking change
      in last 90 days without a migration period.
- [ ] When a stream team needs something new, "extend the platform"
      is a credible option, not "build it yourself again."
