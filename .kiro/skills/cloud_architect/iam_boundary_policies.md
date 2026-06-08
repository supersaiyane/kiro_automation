---
id: iam_boundary_policies
version: 1.0.0
owners: [cloud_architect, security_engineer]
tags: [iam, least-privilege, scp, permissions-boundary, role-design]
when_to_use: |
  Designing or auditing identity + access for any cloud workload.
  IAM is the most-exploited weak point in cloud security — over-
  permissioned roles + long-lived keys cause the bulk of cloud
  breaches. Boundary policies are the safety net that prevents
  even a compromised role from doing maximum damage.
inputs:
  - workload_inventory, human_team_structure, threat_model
outputs:
  - "iam_design: role hierarchy + boundaries + access patterns + audit cadence"
---

# IAM Boundary Policies — The Safety Net Against Over-Permissioning

> Least privilege is the goal; permission boundaries are the
> physics-level enforcement that even if you mess it up, the
> blast radius is bounded. Use them.

## The IAM stack — each layer is independent

```
┌─────────────────────────────────────────────┐
│ Org-level SCP / Policy        (DENY only)   │ ← strongest, can't be bypassed
├─────────────────────────────────────────────┤
│ Permission Boundary on the principal        │ ← caps maximum permissions
├─────────────────────────────────────────────┤
│ Identity-based policy (attached to role)    │ ← grants permissions
├─────────────────────────────────────────────┤
│ Resource-based policy (on the resource)     │ ← grants access from outside
├─────────────────────────────────────────────┤
│ Session policy (per-session)                │ ← can narrow further at use time
└─────────────────────────────────────────────┘
```

Effective permission = intersection of all five. Anywhere a layer
DENIES, the action is blocked.

## Permission boundaries — the killer feature

A permission boundary is the MAXIMUM a role can do, regardless of
what its identity-based policy says.

```json
// boundary-developer (attached to dev-team roles)
{
  "Statement": [
    { "Effect": "Allow",
      "Action": ["ec2:*", "s3:*", "lambda:*", "dynamodb:*"],
      "Resource": "*" },
    { "Effect": "Deny",
      "Action": ["iam:*", "organizations:*", "kms:Delete*"],
      "Resource": "*" },
    { "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringNotEquals": { "aws:RequestedRegion": ["us-east-1", "eu-west-1"] }
      } }
  ]
}
```

Now any role with this boundary CANNOT touch IAM, CANNOT delete
KMS keys, CANNOT use unapproved regions — even if a sloppy policy
grants `Action: *`.

This is the safety net against "a developer attaches AdministratorAccess
in a hurry and forgets."

## Role hierarchy (humans + workloads)

```
HUMANS (via SSO):
├── auditor-readonly         → read everything, modify nothing
├── developer                → bounded by boundary-developer
├── operator                 → bounded by boundary-operator (deploy + restart)
└── admin                    → bounded by boundary-admin (still no root)

WORKLOADS (via IRSA / Managed Identity / Workload Identity):
├── app-prod-orders          → scoped to orders DB + queue
├── app-prod-payments        → scoped to payment DB + Stripe secret
├── ci-deploy                → bounded by boundary-cicd
└── observability-collector  → scoped to write metrics + logs
```

Two principles:
1. ONE role per workload (no shared "app" role).
2. Roles are NEVER assumed cross-workload (orders role can't
   read payments).

## Conditions — the underused leverage

```json
{
  "Effect": "Allow",
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::reports-*/*",
  "Condition": {
    "IpAddress": { "aws:SourceIp": ["10.0.0.0/8"] },
    "Bool":      { "aws:MultiFactorAuthPresent": "true" },
    "StringEquals": { "aws:RequestTag/env": "prod" }
  }
}
```

Conditions add context constraints:
- Source IP (VPC, corporate range).
- MFA presence.
- Time of day (no admin actions outside business hours).
- Tag-based (action only on tagged resources).
- Session age.

## No long-lived keys — OIDC everywhere

For CI/CD:
- **GitHub Actions** → AWS via `aws-actions/configure-aws-credentials`
  with OIDC trust. No key in secrets.
- **Azure DevOps** → Azure via Workload Identity federation.
- **GitLab CI** → AWS / Azure / GCP via OIDC.

For humans:
- SSO via Okta / Azure AD / Google Workspace → STS short-lived
  credentials.

If you have ANY long-lived IAM access keys in production today,
rotate them to OIDC. Detected breach origin is `iam:UserAccessKey`
~ 40% of cloud incidents.

## Break-glass + emergency access

You will, eventually, need to do something the boundary blocks.

- ONE break-glass account, hardware MFA, vault-secured.
- Activation logged separately + paged to security team.
- Auto-deactivation after N hours.
- Quarterly review of who has the credential.

NEVER carve out "in case of emergency" in the regular role's
boundary. That defeats the boundary.

## Access reviews — the audit gives you a deadline

Quarterly:
- Every role's permissions reviewed by its owner.
- Unused permissions removed (AWS Access Analyzer, Azure Entra
  permissions analytics surface these).
- Stale users / service principals deactivated.

A role that hasn't called the API in 90 days is suspect.

## Public exposure — the org-level SCPs

```json
// Deny making things public
{ "Effect": "Deny",
  "Action": ["s3:PutBucketPolicy", "s3:PutBucketAcl"],
  "Resource": "*",
  "Condition": {
    "Bool": { "s3:RequestObjectTagKeys/Public": "true" }
  }
}
```

Plus org policies that enforce: block public access on every S3
bucket / blob container by default. Public requires explicit
escalation.

## Cross-account access

Use AssumeRole / cross-tenant federation, not IAM users in the
target account:

```
[CI account] →assume role→ [Workloads account]
                          ↓
                    [Limited role scoped to one deploy]
```

ExternalId condition prevents the confused-deputy attack:
```json
"Condition": {
  "StringEquals": { "sts:ExternalId": "unique-shared-secret" }
}
```

## Anti-patterns

- **`Action: *, Resource: *`** in production. Common in
  "we'll narrow later." Never narrowed.
- **Long-lived access keys.** Rotation lapses; leaks happen.
- **No boundary on developer roles.** One mistake → org compromise.
- **One IAM user shared by a team.** Audit impossible; rotation
  means coordinating 5 humans.
- **Allowing roles to modify their own permissions** (iam:PutRolePolicy
  granted broadly). Privilege escalation via this is a known TTP.
- **Resource policies that allow `Principal: *`**. Even with
  conditions, this is a sharp edge.
- **No quarterly access review.** Permissions accrete forever.

## Validation

- [ ] No IAM users with console access exist for humans (SSO only).
- [ ] Permission boundaries are attached to all developer +
      operator roles.
- [ ] All CI/CD federates via OIDC; no static access keys.
- [ ] Break-glass account exists, hardware-MFA, monitored.
- [ ] Org-level SCPs block: public storage, region drift,
      IAM modification by non-admin roles.
- [ ] Last quarterly access review completed within 90 days.
- [ ] Roles unused for > 90 days are flagged for review.
