---
id: well_architected_framework
version: 1.0.0
owners: [cloud_architect, architect, security_engineer]
tags: [well-architected, aws-waf, azure-waf, gcp-architecture, pillars]
when_to_use: |
  Designing a new cloud workload, or auditing an existing one
  pre-launch / pre-SOC-2. The Well-Architected Framework gives
  you a shared vocabulary and a non-negotiable checklist that
  every major cloud agrees on. Skip it and you'll discover the
  same gaps the auditor finds — at audit time, expensive.
inputs:
  - workload_design, target_cloud, compliance_scope
outputs:
  - "waf_review: pillar-by-pillar checklist + gaps + remediation plan"
---

# Well-Architected Framework — Pick The Cloud, The Pillars Are The Same

> AWS, Azure, GCP each publish a Well-Architected (or equivalent)
> framework. The pillars rhyme: Operational Excellence, Security,
> Reliability, Performance, Cost, and Sustainability. Use it as a
> checklist; use it as a vocabulary. Auditors definitely will.

## The six pillars (AWS naming; Azure / GCP have direct analogs)

1. **Operational Excellence** — run and monitor systems to deliver
   business value, continuously improve processes.
2. **Security** — protect data, systems, assets; risk assessments,
   mitigation strategies.
3. **Reliability** — recover from failure, dynamically acquire
   resources, mitigate disruptions.
4. **Performance Efficiency** — efficient use of computing
   resources, scale to demand.
5. **Cost Optimization** — avoid unnecessary spend, scale economy.
6. **Sustainability** — minimize environmental impact (added by
   AWS 2021).

## Pillar 1 — Operational Excellence

Key questions:
- How do you observe, monitor, and improve workloads?
- Are deployments codified (IaC) and reversible?
- Do operations support an incident process?

Checklist:
- [ ] IaC (Terraform / CloudFormation / Bicep / Pulumi) for ALL
      production infra. No click-ops.
- [ ] CI/CD with automated rollback.
- [ ] On-call rotation + runbooks per service.
- [ ] Observability: metrics + logs + traces (OpenTelemetry).
- [ ] Game days / chaos drills run periodically.
- [ ] Postmortem culture — incidents produce action items.

## Pillar 2 — Security

Layered defense in depth:

- **Identity foundation** — least-privilege IAM, MFA mandatory,
  no long-lived keys (OIDC federation from CI).
- **Detective controls** — CloudTrail / equivalent on, logs to
  separate account, GuardDuty / equivalent active.
- **Infra protection** — VPC, security groups, WAF, DDoS
  (Shield).
- **Data protection** — encryption at rest (KMS), in transit
  (TLS 1.2+ enforced), key rotation policy.
- **Incident response** — IR runbook, contact tree, breach
  notification timing.

Checklist:
- [ ] No public S3 / blob containers unless intentional.
- [ ] CloudTrail / Activity Log enabled in every region/sub.
- [ ] KMS keys rotate yearly minimum.
- [ ] No IAM users with console access without MFA.
- [ ] Public ingress restricted to load balancers + edge.
- [ ] Secrets in Secrets Manager / Key Vault, NOT environment
      variables or git.

## Pillar 3 — Reliability

Design for failure:

- Multi-AZ for any production tier.
- Multi-region for Tier 1 (per `backup_restore_rto_rpo`).
- Auto-scaling configured + tested.
- Health checks at every layer (LB, target group, app).
- Rate limits + circuit breakers on dependencies.
- Backup + restore drilled (see backup skill).

Checklist:
- [ ] RTO + RPO declared per workload tier.
- [ ] Multi-AZ for OLTP, queues, caches.
- [ ] Auto-scaling target tracking on CPU + custom metrics.
- [ ] Health check + grace period configured per service.
- [ ] DR plan tested in last 12 months.

## Pillar 4 — Performance Efficiency

Right-size + scale:

- Pick the right compute primitive (Lambda / Cloud Run / ECS /
  Fargate / Kubernetes / VM) — see `well_architected_framework`
  decision tree per workload.
- Cache aggressively at every layer (CDN, app, DB).
- Use managed services where possible — they outperform
  hand-rolled at the 80% mark.
- Benchmark before tuning; profile before optimizing.

Checklist:
- [ ] Latency SLO documented per service.
- [ ] CDN in front of all static assets.
- [ ] Database connection pooling (pgbouncer, RDS Proxy).
- [ ] Async workloads use queues (SQS, EventBridge), not API
      polling.
- [ ] Right-sized instances; review quarterly.

## Pillar 5 — Cost Optimization

The biggest leak is "we set it up and never tuned."

- **Right-size**: 90%+ of instances are over-provisioned.
- **Reserved / Savings Plans**: 1-3 year commitments save 30-70%
  on steady workloads.
- **Spot for non-critical**: 70-90% savings on interruptible
  workloads.
- **Lifecycle policies**: S3 / blob storage tiered automatically.
- **Tagging discipline**: chargeback by team / env / cost-center.

Checklist:
- [ ] Cost budget alerts at 50% / 80% / 100% of monthly target.
- [ ] Tagging policy enforced by org policy (not vibes).
- [ ] Reserved Instance / Savings Plan coverage > 50% on steady
      compute.
- [ ] Old EBS snapshots / unused EIPs / detached volumes pruned
      monthly.
- [ ] No "test" or "dev" infra running 24/7 without justification.

## Pillar 6 — Sustainability

Carbon-aware design (newer; many auditors care):

- Pick regions with cleaner grids (Sweden, Quebec).
- Right-size to reduce compute waste.
- Spot / burstable for non-critical workloads.
- Schedule batch jobs in off-peak hours / cleaner-grid times.

Checklist:
- [ ] Region selection considers grid carbon intensity.
- [ ] Auto-scaling DOWN during off-hours.
- [ ] No idle infra > 14 days.

## Reviews — how to actually use the framework

A WAF review is a 2-4 hour structured walkthrough. Per pillar:

1. List the questions (each pillar has ~10 official questions).
2. Score yourself: Acceptable / Improvement Needed / Critical.
3. For "Critical" + "Improvement Needed," write a remediation
   ticket with owner + due date.
4. Schedule the next review (quarterly recommended).

AWS Well-Architected Tool / Azure Advisor / GCP Architecture
Framework all have built-in tools. Use them.

## Anti-patterns

- **WAF as a one-shot document.** It's a recurring review.
- **Selective pillar adoption** (e.g., only Security). Pillars
  trade off; skipping cost means money lost, skipping
  reliability means downtime.
- **Reading the framework after launch.** The point is to inform
  the design.
- **Reviews without owners.** "We should fix this" with no name
  is decoration.
- **Vendor-specific lock-in justified by "the framework said so."**
  The framework is vendor-agnostic; lock-in is your call.

## Validation

- [ ] At least one WAF review per workload tier completed in
      last 12 months.
- [ ] Critical findings have owners + due dates.
- [ ] Cost, reliability, and security pillars each have a named
      owner.
- [ ] Reviews are tracked in a recurring calendar event.
- [ ] Findings feed into the engineering roadmap, not a binder.
