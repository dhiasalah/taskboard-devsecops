# Changelog

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

