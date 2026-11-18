# Changelog

## v0.3 — Persistent DB, backups, non-root

- Postgres is a **StatefulSet** (`taskboard-db-0`) with its own 1Gi disk (PVC): tasks survive restarts
- Headless Service `db-headless` next to the normal `db` Service; still no door to the outside
- Nightly **backup CronJob** (02:00 Europe/Paris, `pg_dump | gzip`, 7 days kept, fails loudly) into its own volume
- A **restore-test Job** proves the newest backup can be loaded, into a scratch database
- **Every Pod non-root**: api UID 10001, web UID 101, db and backup jobs UID 70, all with
  `allowPrivilegeEscalation: false` and every Linux capability dropped
- web and api **spread over both workers** (`topologySpreadConstraints`): one node down no longer means TaskBoard down
- `scripts/status.ps1`: a read-only first look (nodes, Pods, restarts, endpoints, warnings, drift, non-root check)
- `docs/runbook.md`: how to read and fix the 5 classic failures
- Security gaps 2 (root database) closed and 10 (root backup) half closed: see `docs/security-gaps.md`

## v0.2 — Runs on Kubernetes

- Runs on a local 3-node kind cluster, in its own `taskboard` namespace
- API (3 Pods) and web page (2 Pods) as Deployments with rolling updates and rollback history
- Postgres on Kubernetes; settings in a ConfigMap, password in a Secret made from a Git-ignored file
- ClusterIP Services only (`web`, `api`, `db`): nothing open on the network
- Startup, readiness and liveness probes on every part
- Requests and limits on every container, plus a LimitRange for the namespace
- Images pinned by digest
- `scripts/up.ps1` builds everything from zero with one command, safe to run twice; `scripts/down.ps1` removes it
- Known security gaps written down with their fix: `docs/security-gaps.md`

## v0.1 — Containerized app

- Web page, Flask API and Postgres, each in its own container
- One command to run: `docker compose up -d`
- Non-root images, with Trivy scans
- The database has no door on the laptop, and only the API can reach it
- Images published on Docker Hub

