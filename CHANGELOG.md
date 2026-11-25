# Changelog

## v0.4 — Helm chart + Kustomize overlays

- **Helm chart** `charts/taskboard/` (chart 0.2.0, app 0.2), running as the release `taskboard` in `taskboard-helm`
  - Secure by default: non-root, drop ALL, read-only root disk, ClusterIP only, with no values at all
  - Asks for the Secret's **name** (`existingSecret`), never the password; the backup disk survives `helm uninstall`
  - Helpers in `_helpers.tpl`, a backup switch (`backup.enabled`) and a `backup.keepDays` knob
- **Kustomize**: `k8s/` is now `base/` (10 shared files, no namespace inside) + `overlays/dev` + `overlays/prod`
  - `dev` (`taskboard-dev`): 1 api, 1 web, its own empty database, no backups
  - `prod` (`taskboard`): nightly backups, and `lock.yaml` gives **every container a read-only root disk**
    (small `emptyDir` folders for `/tmp` and `/var/run/postgresql`)
  - every object carries `environment=dev` or `environment=prod`, outside the selectors
- **kube-linter** checks what is shipped: the prod overlay and the chart have no findings; the one ignored
  check (`no-anti-affinity`, Pods are already spread) has its reason written on the object
- `scripts/up.ps1` builds TaskBoard from the prod overlay (`kubectl apply -k k8s\overlays\prod`)

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

