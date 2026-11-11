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

## Run with Docker Compose
1. Copy `.env.example` to `.env`, then change the password
2. `docker compose up -d`
3. Open http://localhost:8080

Images: [dhiasalah on Docker Hub](https://hub.docker.com/u/dhiasalah)

## Project structure
- `app/api/`: the Python API
- `app/frontend/`: the web page
- `docs/`: diagrams and design decisions, starting with the [network plan](docs/network-plan.md)
- `k8s/`: the Kubernetes manifests (Deployments, Services, ConfigMap, LimitRange)
- `cluster/`: the kind cluster config (1 control plane + 2 workers)
- `scripts/`: helper scripts, including `up.ps1` and `down.ps1`
- `docker-compose.yml`: starts everything
- `CHANGELOG.md`: what changed in each version

## Why this project
I am learning DevSecOps to become a DevSecOps engineer, and I learn best by building one real project from start to finish.

## Author
Ben Salah Mohamed Dhia, learning DevSecOps step by step. See JOURNEY.md.
