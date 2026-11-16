# TaskBoard — a secure GitOps platform on Kubernetes

A tiny to-do app (web page + API + database) running on a secured,
automated Kubernetes platform that I am building from zero.

## Status
✅ v0.1: the app runs in containers.
✅ v0.2: the app runs on Kubernetes (a local kind cluster). Known security gaps: [docs/security-gaps.md](docs/security-gaps.md).

![Architecture](docs/architecture.svg)

## Run on Kubernetes
Needs Docker Desktop, `kind` and `kubectl`.

1. Make the private password file `secrets/db.env` once (it is Git-ignored), with one line:
   `POSTGRES_PASSWORD=<a long random password>`
2. Build everything (cluster, namespace, Secret, app) with one command: `.\scripts\up.ps1`
3. Open a tunnel: `kubectl port-forward -n taskboard svc/web 8080:80`, then open http://localhost:8080
4. Smoke test, in another terminal: `Invoke-RestMethod http://localhost:8080/api/health` → `ok 0.2`
5. Remove it all: `.\scripts\down.ps1`

`up.ps1` is safe to run again: a second run only says `unchanged`.

## Database backups
A CronJob (`k8s/db-backup-cronjob.yaml`) dumps the database every night at 02:00 (Paris time) into its own
volume, and keeps 7 days of backups.

- Run a backup now: `kubectl create job --from=cronjob/db-backup backup-now -n taskboard`
- Prove the newest backup can be restored (into a scratch database, the real data is not touched):
  `kubectl apply -f jobs\restore-test.yaml`, then `kubectl logs job/restore-test -n taskboard`

Known limits: the backups live on the same machine as the data and are not encrypted yet
(see [docs/security-gaps.md](docs/security-gaps.md)).

## When something breaks
Run `.\scripts\status.ps1` first. It only reads: nodes, Pods, restarts with the last exit code, the Pods
behind each Service, and recent warnings. Then follow the [runbook](docs/runbook.md).

## Run with Docker Compose
1. Copy `.env.example` to `.env`, then change the password
2. `docker compose up -d`
3. Open http://localhost:8080

Images: [dhiasalah on Docker Hub](https://hub.docker.com/u/dhiasalah)

## Project structure
- `app/api/`: the Python API
- `app/frontend/`: the web page
- `docs/`: diagrams, design decisions, the [network plan](docs/network-plan.md) and the [runbook](docs/runbook.md)
- `k8s/`: the Kubernetes manifests (Deployments for web and api, a StatefulSet with its own disk for Postgres, Services, ConfigMap, LimitRange, the nightly backup CronJob)
- `jobs/`: Jobs I run by hand, like the backup restore test
- `cluster/`: the kind cluster config (1 control plane + 2 workers)
- `scripts/`: helper scripts: `up.ps1`, `down.ps1`, and `status.ps1` (read-only first look)
- `docker-compose.yml`: starts everything
- `CHANGELOG.md`: what changed in each version

## Why this project
I am learning DevSecOps to become a DevSecOps engineer, and I learn best by building one real project from start to finish.

## Author
Ben Salah Mohamed Dhia, learning DevSecOps step by step. See JOURNEY.md.
