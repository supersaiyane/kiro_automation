---
id: twelve_factor_app
version: 1.0.0
owners: [devops_engineer, backend_lead]
tags: [twelve-factor, ci-cd, deploy, config, containers]
when_to_use: |
  Setting up a new service's CI/CD + deployment, or reviewing whether
  an existing service is cloud-deployable cleanly.
inputs:
  - service_repo: code + Dockerfile + pipeline
outputs:
  - twelve_factor_report: per-factor compliance + remediation list
---

# The Twelve-Factor App (relevant excerpts)

1. **Codebase** — one repo per deployable unit, many deploys.
2. **Dependencies** — declared explicitly (lockfile), never relying on
   system packages.
3. **Config** — in the environment (12-factor's most-violated rule).
   No secrets in the repo, no per-env constants in code.
4. **Backing services** — DB, cache, queue treated as URLs in env.
   Swap dev sqlite → prod postgres without code change.
5. **Build / Release / Run** — strict separation. Build produces an
   image, release combines image + config, run starts the process. No
   building on the prod host.
6. **Processes** — stateless. Any state goes to a backing service.
7. **Port binding** — the app exports its own HTTP, no external server.
8. **Concurrency** — scale by running more processes, not threads.
9. **Disposability** — fast startup, graceful shutdown on SIGTERM.
10. **Dev/prod parity** — same Postgres in dev as prod, not sqlite.
11. **Logs** — stdout. The platform aggregates.
12. **Admin processes** — one-off jobs share the same code + env as
    the running process (migrations, repl).

**Anti-patterns**
- Reading config from a file on the host instead of env vars.
- Process writing to local disk and expecting it next request.
- Logging to a file instead of stdout.
- Migrations as a separate codebase from the app.
