---
id: iac_terraform_patterns
version: 1.0.0
owners: [devops_engineer, sre, architect]
tags: [terraform, opentofu, iac, modules, state, drift, atlantis]
when_to_use: |
  Provisioning cloud infra (AWS, GCP, Azure, k8s control plane,
  DNS, IAM). Click-ops works for prototypes; for production it
  produces undocumented drift you can't reproduce. IaC is the
  discipline that makes infra reviewable, revertable, and
  reproducible.
inputs:
  - target_clouds, env_count, team_size
outputs:
  - "iac_design: module structure + state strategy + apply policy + drift policy"
---

# IaC With Terraform / OpenTofu — Patterns That Survive at Scale

> Terraform code that works for 1 environment fails for 5. Terraform
> code that works for 5 fails for 50. The discipline is in module
> boundaries, state isolation, and review automation — not in
> writing `resource "aws_..."` blocks.

## Terraform vs OpenTofu (2026)

OpenTofu is a community-driven fork of Terraform after HashiCorp's
2023 BSL license change. As of 2026:

- OpenTofu is fully compatible with Terraform 1.5 syntax.
- OpenTofu has added features Terraform hasn't (state encryption,
  early variable evaluation).
- Major modules and providers work in both.

Pick OpenTofu for new green-field work unless you're already deep
in Terraform Cloud / Enterprise. Migration is `s/terraform/tofu/`
in CLI invocations.

## The state file — most important file in your infra

State is HashiCorp Configuration Language's memory of what it
created. Lose it → Terraform doesn't know what exists. Two state
files for the same resources → either one apply wins, the other
deletes things.

Rules:
1. **Never local state in production.** Always remote backend
   (S3 + DynamoDB lock, GCS, Azure blob, Terraform Cloud).
2. **One state per (environment, blast-radius unit).** Not one
   monolith for the whole company.
3. **State must be encrypted at rest** (S3 SSE-KMS, GCS CMEK).
4. **State has secrets in it** (DB passwords, API keys). Treat as
   secrets-class data. Access-control aggressively.
5. **State locking is mandatory.** Two concurrent applies = corrupted
   state.

## Module organization

```
infra/
├── modules/                   ← reusable building blocks
│   ├── network/
│   ├── eks-cluster/
│   ├── rds-postgres/
│   └── service/               ← "one of our services in EKS"
├── environments/
│   ├── staging/
│   │   ├── main.tf            ← composes modules
│   │   └── terraform.tfvars
│   └── prod/
│       └── main.tf
└── policies/                  ← OPA / Sentinel
```

Discipline:
- A module is FROZEN INTERFACE. Inputs (variables) and outputs are
  the contract. Don't break them between versions.
- Modules version themselves (`source = "git::...?ref=v1.4.0"`).
  Bumps are PRs, not in-place edits.
- Modules do ONE thing. "A VPC" or "an RDS." Not "everything."
- Environments are THIN — they compose modules with environment-specific
  inputs. Almost no raw resource blocks in environments/prod/main.tf.

## State boundaries — blast radius design

Bad: one state for ALL of prod (network + DB + every service).
- Risk: `apply` corruption can destroy 100 resources.
- Slow: a 4,000-resource state takes minutes per plan.
- Coupling: changing one service requires permission to all.

Good: states tiered by blast radius.

```
prod-platform/    ← VPC, k8s control plane, shared DNS
prod-data/        ← DB, cache, queue. Rarely changed.
prod-app-X/       ← one service. Changes daily.
prod-app-Y/
```

Cross-state references via:
- `terraform_remote_state` data source (read-only).
- A registry / SSM Parameter Store / Consul (resource ID lookup).

A cross-cutting change (e.g., a new VPC subnet) is one apply on
`prod-platform`. Service applies don't touch it.

## The plan → review → apply pipeline

NEVER `terraform apply` from a laptop into prod. Always:

```
1. PR opened with terraform change.
2. CI runs `terraform plan` for affected states.
3. Plan output is posted to the PR (Atlantis, Spacelift, env0,
   Terraform Cloud).
4. Reviewers approve plan, not just code (the diff often surprises).
5. Merge triggers `terraform apply` in a privileged runner.
6. Apply output, including any unexpected changes, posted back.
```

This is gitops for infra. Drift detection runs periodically and
opens PRs to revert manual changes.

## Policy as code — Conftest / OPA / Sentinel

Reject the plan AT PR TIME if it violates policy:

```rego
# block public S3 buckets
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  resource.change.after.acl == "public-read"
  msg = sprintf("S3 bucket %s is public", [resource.address])
}
```

Common rules:
- No 0.0.0.0/0 ingress except on load balancers.
- All EBS / RDS storage is encrypted.
- IAM policies don't have `Action: "*"` on `Resource: "*"`.
- Tags are present (cost-center, owner, env).

Policy as code keeps reviews on intent, not on catching the same
classes of mistake.

## Multi-environment without copy-paste

```hcl
# environments/staging/main.tf
module "service_api" {
  source = "../../modules/service"

  name        = "api"
  environment = "staging"
  replicas    = 2
  cpu         = "500m"
  memory      = "1Gi"
}

# environments/prod/main.tf — same module, different inputs
module "service_api" {
  source = "../../modules/service"

  name        = "api"
  environment = "prod"
  replicas    = 8
  cpu         = "2000m"
  memory      = "4Gi"
}
```

Promotion is a code review of input changes, not a 200-line
manifest diff.

## Imports — for "we already have it"

You will inherit click-opped infra. Don't rebuild — import:

```bash
tofu import aws_iam_role.legacy arn:aws:iam::123:role/old-role
```

Then write the matching `resource` block to match the imported state.
Plan should be no-op after a good import.

Imports are tedious; use `terraformer` for bulk imports of existing
accounts.

## Anti-patterns

- **Local state in prod.** Lost laptop = lost infra.
- **One mega-state.** Plan times grow linearly; blast radius is huge.
- **Hand-edited state files.** Recoverable maybe, traumatic for
  sure. Use `terraform state` subcommands or just re-import.
- **`count` / `for_each` on resources that need stable identity.**
  Reordering causes destroy-and-recreate. Use `for_each` with map
  keys, not `count` with index.
- **Hard-coded secrets in `.tfvars`.** Always pull from a secret
  manager via data sources.
- **`terraform destroy` in CI.** One bad merge = production gone.
  Destroys are explicitly run by a human with eyes on.
- **Provider version unpinned.** Reproducibility lost. Pin in
  `required_providers`.
- **Tabs of `terraform apply` open by every engineer.** They WILL
  step on each other despite locking. Centralize applies.

## OpenTofu's new tricks worth using

- **State encryption (native)**: encrypt the state file with a KMS
  key, not just at-rest.
- **Early variable eval**: `for_each = var.list` works in places
  that errored on Terraform.
- **Provider mock** for unit-testing modules without real APIs.

## Validation that IaC is mature

- [ ] No engineer has `terraform apply` capability on prod from
      their laptop.
- [ ] Drift detection runs daily; drift PRs are reviewed within 24h.
- [ ] A new environment can be created from existing modules in
      < 1 day.
- [ ] Plan output is posted on every PR; reviews block on it.
- [ ] Policy checks run on every plan; failures block merge.
- [ ] State files are encrypted at rest and access-logged.
- [ ] Module versions are pinned; bumps are PRs.
