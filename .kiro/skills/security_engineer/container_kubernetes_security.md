---
id: container_kubernetes_security
version: 1.0.0
owners: [security_engineer, devops_engineer, sre]
tags: [k8s, container, image-scanning, admission, runtime, network-policy, falco]
when_to_use: |
  Running workloads on Kubernetes, ECS, EKS, GKE, AKS, OpenShift. The
  shared-tenancy / shared-kernel model in containers gives attackers
  multiple new doors: image bugs, pod compromise, container escape,
  cluster API. Each requires distinct controls.
inputs:
  - cluster_topology, image_pipeline, workload_inventory
outputs:
  - "k8s_security_baseline: image scan + admission + RBAC + network policy + runtime detection"
---

# Container + Kubernetes Security

> The container shares the host kernel. Compromise inside a pod can
> escalate to host if the pod is privileged. K8s RBAC + admission +
> runtime detection are the layered defenses.

## The four layers of K8s security (4Cs)

```
┌─────────────────────────────────────┐
│  CODE       — your application       │
│  CONTAINER  — image + base + runtime │
│  CLUSTER    — k8s control plane      │
│  CLOUD/CORP — VPC, IAM, hardware     │
└─────────────────────────────────────┘
```

Apply controls at every layer.

## Container image security

### Base image
- **Distroless** (gcr.io/distroless/...) or **Chainguard** / Wolfi.
  Zero shell, zero package manager, ~70% fewer CVEs.
- Pin by digest, not tag (`@sha256:...`).
- Multi-stage builds; final image has only what's needed.
- Run as **non-root user** (`USER 1000` in Dockerfile).
- Read-only root filesystem at runtime.

### Image scanning (CI)
- Trivy, Grype, Snyk Container, AWS Inspector, Anchore.
- Block push to registry on Critical CVE (in prod-bound).
- Scan on schedule (nightly) — new CVEs match old images.

### Image signing (SLSA / Sigstore)
- See `supply_chain_sbom_slsa`.
- Sign with cosign keyless OIDC.
- Admission controller verifies signature before pull.

## Cluster — RBAC

Default principle: **no service account auto-mounted**. Set
`automountServiceAccountToken: false` for pods that don't need k8s API
access (most apps don't).

For pods that DO need k8s API:
- Dedicated service account.
- Bound to specific Role / ClusterRole.
- Verbs MINIMAL — `get`, `list`, `watch` rarely needs `update` / `delete`.

```yaml
# Bad
kind: ClusterRoleBinding
roleRef: { kind: ClusterRole, name: cluster-admin }
subjects: [{ kind: ServiceAccount, name: default }]

# Good
kind: Role           # namespace-scoped
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
```

Audit: NEVER use `cluster-admin` for workloads. Periodic review with
`kubectl-who-can` or rbac-lookup.

## Cluster — admission control

Tools (pick one):
- **Kyverno** — YAML-first policies, Kubernetes-native.
- **OPA Gatekeeper** — Rego-based, powerful but steep learning curve.
- **Datree / Polaris** — pre-built sane defaults.

Baseline admission policies:

```yaml
# Kyverno examples
# Block privileged pods
- name: disallow-privileged
  validationFailureAction: Enforce
  rules:
    - name: privileged
      match: { any: [{ resources: { kinds: [Pod] }}]}
      validate:
        message: "privileged containers not allowed"
        pattern:
          spec:
            =(securityContext): { =(privileged): "false" }
            containers:
              - =(securityContext): { =(privileged): "false" }

# Require signed images
- name: require-signed-images
  ...

# Require resource limits
- name: require-resource-limits
  ...

# Block latest tag
- name: disallow-latest-tag
  ...
```

Mandatory policies for prod:
- No privileged: true
- No hostNetwork: true / hostPID: true / hostIPC: true
- No hostPath volumes (except documented exceptions)
- Resource limits set (CPU + memory)
- No latest tag
- Images signed by trusted issuer
- runAsNonRoot: true
- readOnlyRootFilesystem: true

## Pod security standards (PSS)

Replace deprecated PodSecurityPolicy. Three levels:

| Level | Use |
|---|---|
| **Privileged** | Trusted system workloads (rare) |
| **Baseline** | Minimum to prevent known escalation |
| **Restricted** | Hardened; matches industry defaults |

Set on namespace:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: prod-payments
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

Restricted enforces a long list of best practices automatically. Use this
for prod; loosen only with named exceptions.

## Network policy

Default-deny + explicit allow:

```yaml
# Default deny ingress in namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: default-deny, namespace: prod }
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
```

Then per-app allow:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: api-allow, namespace: prod }
spec:
  podSelector: { matchLabels: { app: api } }
  ingress:
    - from:
        - podSelector: { matchLabels: { app: web } }
      ports: [{ port: 8080 }]
  egress:
    - to: [{ podSelector: { matchLabels: { app: db } }}]
      ports: [{ port: 5432 }]
```

CNI must support NetworkPolicy (Calico, Cilium, AWS VPC CNI w/ enforcement).

For app-layer (mTLS, identity-based authz): service mesh (Istio, Linkerd,
Cilium Service Mesh).

## Secrets

- NOT in env vars committed to git, NOT in ConfigMaps.
- Use Secrets API + at-rest encryption (encryption providers: AWS KMS, Azure
  Key Vault, Vault).
- Better: External Secrets Operator pulls from KMS / Vault at runtime.
- For dev: sealed-secrets / SOPS for git-storable encrypted secrets.

Mount secrets via volumes (not env vars) where possible — `env` shows in
`ps`; files have stricter access.

## Runtime detection

Static admission ≠ runtime monitoring. Tools:

- **Falco** (CNCF) — eBPF-based syscall monitoring; rules for:
  - Container running `bash`
  - Unexpected outbound connection
  - Container modifying `/etc`
  - Privileged container starting
- **Tetragon** (Cilium / eBPF) — broader observability.
- **Sysdig Secure** / **Aqua** / **Wiz Runtime** — commercial.

For high-risk workloads (payments, regulated): runtime detection is
required.

## Image runtime hardening

- **gVisor** (sandbox runtime) — userspace kernel, much harder escapes.
- **Kata Containers** — VM-isolated containers; closer to VM security.
- For most workloads: standard runtime + restricted PSS is enough.

## EKS / GKE / AKS specifics

- **EKS**: enable Pod Identity (replaces IRSA), enable control-plane
  logging, use Inspector for image scan.
- **GKE**: Workload Identity, Binary Authorization (image signing),
  Confidential GKE for crypto isolation.
- **AKS**: Microsoft Entra Workload ID, Azure Policy for K8s, Microsoft
  Defender for Cloud.

For all: **CIS Benchmark** scan (kube-bench) — many controls preset.

## Supply chain at cluster level

Don't deploy random Helm charts:
- Pin chart versions.
- Audit chart values for privileged: true, hostNetwork, default service
  account with cluster-admin.
- Scan chart for known IOCs.
- Curate an internal registry of approved charts.

## Anti-patterns

- **Default service account with auto-mount.** Compromise of any pod →
  k8s API token.
- **`hostNetwork: true`** routinely. Pod gets host's network namespace —
  bypass network policy.
- **No network policy.** Pod-to-pod is wide open by default in most CNIs.
- **Privileged containers** for "convenience." Escape risk.
- **`latest` tag in prod.** Surprise re-deploys + unknown image content.
- **No image scanning + scanning only at registry push** — CVEs found
  POST-deploy go silent.
- **Cluster-admin role for the CI service account.** Workflow bug = total
  cluster compromise.
- **Logs / secrets / ConfigMaps with API keys in plaintext.**

## Validation

- [ ] All prod namespaces enforce PSS Restricted.
- [ ] NetworkPolicy default-deny in every prod namespace.
- [ ] Admission controller (Kyverno/OPA) enforces image signature + no
      privileged.
- [ ] Image scanning runs in CI + nightly against registry.
- [ ] kube-bench CIS benchmark scan green.
- [ ] Falco / runtime detection deployed for sensitive workloads.
- [ ] No service account has cluster-admin in prod.
- [ ] Secrets externalized via Vault / KMS, not stored in ConfigMaps.
