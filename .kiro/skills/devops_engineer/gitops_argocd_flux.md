---
id: gitops_argocd_flux
version: 1.0.0
owners: [devops_engineer, sre]
tags: [gitops, argocd, flux, kubernetes, declarative-deploy, drift]
when_to_use: |
  Kubernetes (or any declarative platform) where deploys are
  currently `kubectl apply` from a CI pipeline. GitOps moves
  the reconciliation loop INTO the cluster — git becomes the
  source of truth, the cluster pulls instead of CI pushing.
inputs:
  - cluster_inventory, current_deploy_model, secret_strategy
outputs:
  - "gitops_design: repo structure + reconciler choice + secret + drift policy"
---

# GitOps — Declarative, Pulled, Continuously Reconciled

> Push-based "CI deploys" rely on a chain of credentials, networks,
> and runners that can break in 17 ways. Pull-based GitOps has the
> cluster reconcile itself against a git repo as the only source of
> truth — the surface area shrinks dramatically.

## The four GitOps principles (OpenGitOps)

1. **Declarative** — the entire desired state is in a git repo.
2. **Versioned and immutable** — git history is the audit log.
3. **Pulled automatically** — an in-cluster reconciler closes the
   loop without external push.
4. **Continuously reconciled** — drift is detected and corrected
   automatically.

If your "GitOps" runs `kubectl apply` from GitHub Actions, that's
CIOps — different beast, weaker guarantees, no drift detection.

## Argo CD vs Flux (2026 snapshot)

| Concern | Argo CD | Flux |
|---|---|---|
| UI | Rich web UI, mature | CLI-first, has weave-gitops UI |
| Multi-cluster | Native (ApplicationSet) | Native (multi-tenancy via Kustomize) |
| Helm support | First-class | First-class |
| OCI source | Yes | Yes |
| Image automation | ArgoCD Image Updater (add-on) | Native (image-reflector + image-automation) |
| Notifications | Built-in | Built-in |
| ApplicationSets | Yes (matrix, list, git, cluster) | Yes (Flux v2 KustomizationSet) |

Choose based on:
- **Argo CD** if you want a strong UI for app developers and a single
  pane across N clusters.
- **Flux** if you prefer CLI/GitOps-native, want native image automation,
  and don't want a UI tier.

Both are CNCF graduated. Either is a defensible choice.

## Repo layout — keep state and code SEPARATE

```
infra-repo/                   ← Argo CD / Flux watches this
├── apps/
│   ├── web/
│   │   ├── base/
│   │   │   ├── deployment.yaml
│   │   │   └── service.yaml
│   │   └── overlays/
│   │       ├── staging/
│   │       │   └── kustomization.yaml
│   │       └── prod/
│   │           └── kustomization.yaml
│   └── api/
└── clusters/
    ├── staging/
    │   └── argocd-apps.yaml  ← which apps + overlays go here
    └── prod/

app-repo/                     ← source code
├── src/
└── .github/workflows/ci.yml  ← builds image, opens PR in infra-repo
```

**The split**: application code in one repo, deployment manifests
in another. CI builds the image, opens a PR in the infra repo
updating the image tag. Merging the PR triggers reconciliation.

Benefits:
- App devs can move fast in app-repo without affecting deploys.
- Infra repo has different review rules (more eyes on prod changes).
- Reverts are git reverts, period.

## The "push image, open PR" pipeline

```yaml
# .github/workflows/ci.yml in app-repo
- name: Build + push image
  run: |
    docker build -t ghcr.io/org/app:${{ github.sha }} .
    docker push   ghcr.io/org/app:${{ github.sha }}

- name: Open PR in infra-repo
  uses: peter-evans/create-pull-request@v6
  with:
    repository: org/infra-repo
    commit-message: "bump app to ${{ github.sha }}"
    branch: bump-app-${{ github.sha }}
    title: "Deploy app:${{ github.sha }} to staging"
```

A bot opens the PR, a human reviews, merge → staging reconciles.
Promotion to prod = another PR that updates the prod overlay.

## Drift detection — what GitOps catches that CIOps doesn't

A teammate runs `kubectl edit deployment` on prod. CIOps: invisible.
GitOps: reconciler notices `live != desired`, either:
- **Auto-prunes** the change (recommended for prod).
- **Alerts** and lets a human decide (good for shared infra).

This is the single biggest operational win. "Configuration that
drifts" is the silent killer of incident postmortems; GitOps
eliminates the failure mode.

## Secrets — what doesn't go in git

Git is for declarative manifests, not secrets. Three approved patterns:

1. **Sealed Secrets** (Bitnami) — secrets are encrypted to the
   cluster's public key, then committed. Only the cluster can
   decrypt. Simple, works offline.
2. **External Secrets Operator (ESO)** — manifests reference
   secrets stored in AWS Secrets Manager, Vault, GCP Secret
   Manager. The cluster pulls and creates k8s Secrets at
   reconcile time. Best for centralized secret management.
3. **SOPS-encrypted** files in git, decrypted by Flux/ArgoCD with
   a KMS-backed key. Strong audit trail.

DO NOT put plaintext secrets in git. DO NOT use the same key
across all environments. Rotate the keys per environment.

## Progressive rollouts — Argo Rollouts / Flagger

Default k8s Deployment is rolling update only. For canary, blue-green,
and traffic-shifting, layer Argo Rollouts (Argo) or Flagger (Flux):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  strategy:
    canary:
      steps:
        - setWeight: 10
        - pause: { duration: 5m }
        - setWeight: 50
        - pause: { duration: 10m }
        - setWeight: 100
      analysis:
        templates:
          - templateName: success-rate
        startingStep: 1
```

`analysis` ties the rollout to a Prometheus query: success rate
must hold above X% or auto-rollback.

## Multi-cluster + multi-tenancy

For 5+ clusters, hand-rolled `Application` manifests don't scale.

- **Argo CD ApplicationSets**: one generator (list of clusters or
  git directories) → N Applications.
- **Flux KustomizationSets**: same idea.
- Cluster API + Crossplane for the cluster lifecycle itself.

Apply the SAME repo layout discipline at every layer — declarative,
versioned, reconciled.

## Observability for GitOps

- **Sync status per Application**: red if drift, yellow if syncing.
- **Reconcile latency**: > 5 min sustained = reconciler problem.
- **Failed sync events**: a manifest with a typo → sync fails;
  page on consecutive failures.
- **Drift counter**: monthly review of how often drift was detected
  → tightens process upstream.

## Anti-patterns

- **Push from CI AND pull from cluster.** Either git is truth or
  CI is. Pick one. Two sources = drift forever.
- **One mega-repo holding everything for all clusters.** Blast
  radius of a bad merge is huge. Tier by environment.
- **Secrets in git "encrypted with our key" (custom).** Use
  Sealed Secrets / SOPS / ESO. Don't roll your own.
- **Manual `kubectl apply` allowed in prod.** Even by SREs.
  Emergency overrides should be PR-as-fast-as-possible, not bypassing.
- **Auto-prune off in prod.** Drift will accumulate. Turn it on
  with confidence built via staging.
- **Skipping the staging tier.** Every change goes through staging.
  GitOps makes this almost free (same repo, different overlay).
- **`:latest` image tags.** Reconciler thinks nothing changed.
  Pin by digest or immutable tag.

## Validation that GitOps is real

- [ ] Every prod manifest came from a merged PR.
- [ ] `kubectl edit` in prod is detected and reverted within 5 min.
- [ ] Reverting a deploy = `git revert` + automatic reconcile.
- [ ] No long-lived kubeconfigs sit on CI runners.
- [ ] Secrets in git are encrypted; the key is held by the cluster,
      not by CI.
- [ ] You can stand up a NEW environment from the same repo with
      one cluster bootstrap + one branch.
