# 🚀 My DevSecOps Journey — TaskBoard

## Lesson 01 — What is DevOps / DevSecOps? + the terminal (2026-10-25)
- Learned: DevSecOps = security in every step. My first commands: pwd, ls, cd, mkdir.
- Broke: `docker` failed in Ubuntu with `failed to connect to the docker API at unix:///var/run/docker.sock ... no such file or directory`.
- Fixed: the socket file didn't exist because Docker Desktop's WSL integration was off for Ubuntu. Turned on Settings → Resources → WSL integration → Ubuntu, restarted Docker Desktop. `docker version` now shows a `Server:` section.
- Security note: `docker.sock` = full control of the machine. Never expose it or mount it into a container.

## Lesson 02 — Files, folders, permissions & nano (2026-10-25)
- Learned: cp / mv / rm, wildcards, editing with nano, reading `-rwxr-xr-x`, chmod with letters (`u+x`) and numbers (`644`, `755`, `600`), chown.
- Broke: nothing this time 🎉
- Fixed: —
- Security note: played the attacker with the `nobody` user. At 644 it could read my fake password, at 600 it was blocked, at 777 it overwrote the file. Never `chmod 777`; secrets get `600`.
- Project: built the skeleton (`app/api`, `app/frontend`, `docs`, `scripts`) and wrote the first README.md with nano.

## Lesson 03 — Processes, apt, env variables, pipes & scripts (2026-10-26)
- Learned: ps/kill, apt, export, pipes, my first real script
- Broke: nothing
- Fixed: nothing

## Lesson 04 — Networking: IP, ports, DNS, HTTP, curl (2026-10-31)
- Learned: IP addresses, ports, DNS, HTTP requests and status codes, curl.
- Project: wrote `docs/network-plan.md`: frontend 8080 → api 5000 → postgres 5432, database never exposed.

## Lesson 05 — Git & GitHub (2026-10-31)
- Project: the repo went public on GitHub, with a `.gitignore` for secrets and a finished README.
- Security note: commits use my GitHub noreply address, so my real email stays private.

## Lesson 06 — Containers & Docker (2026-10-31)
- Learned: images vs containers, ports, volumes, bind mounts, Docker networks. Containers lose their files when removed, volumes don't.
- Broke: `git status` failed with `Unable to read current working directory` on `/mnt/c`.
- Fixed: my terminal had lost its link to the folder. A fresh `cd` into the project fixed it.
- Security note: `docker inspect` shows passwords passed with `-e`. The database has no published port, so only containers on its network can reach it.
- Project: `scripts/taskboard-up.sh` starts the web server and database, following my network plan.

## Lesson 07 — Dockerfile (2026-11-02)
- Learned: Dockerfiles, layers and the build cache, RUN vs CMD, non-root users, Trivy scans.
- Broke: my first quiz try was 5/10, mostly on published ports and the cache order.
- Fixed: went through them again. An arrow means published, `0.0.0.0` means every address, and no arrow means only the container's network.
- Project: wrote the API, the web page and their Dockerfiles. TaskBoard now really saves tasks.

## Lesson 08 — YAML + Docker Compose + Docker Hub (2026-11-02)
- Learned: YAML, Compose services, healthchecks, and how a port with no address opens to everyone.
- Broke: in PowerShell, `curl` ran `Invoke-WebRequest` instead of the real curl. I also built my images with the placeholder name `YOURNAME`.
- Fixed: used `curl.exe`, found the cause with `Get-Alias curl`, and renamed the images.
- Security note: split `web` and `db` onto separate networks, so `web` can't even find the database. Trivy on the API: 0 CRITICAL, 5 HIGH in Python install tools. Web image: 0.
- Project: one command starts TaskBoard. From now on I work in PowerShell and VS Code.

## Lesson 09 — Why Kubernetes? (2026-11-02)
- Learned: desired state, actual state, and the parts of a cluster.
- Broke: on purpose, I killed the API and tried to scale it. Compose didn't bring it back, and the port was already taken.
- Fixed: first I thought the kubelet remembers what you ask for. It's etcd. And a leaked `kubeconfig` needs its key revoked, not a shutdown.
- Project: v0.1 is released, with my images on Docker Hub.

## Lesson 10 — kubectl + kind, first cluster (2026-11-02)
- Learned: kind runs each Kubernetes node as a Docker container, and `kubectl` talks to the API server.
- Fixed: I didn't know what kind can't do. All 3 nodes live on one laptop, so one failure stops them all.
- Security note: `kubeconfig` is a password, so it stays out of Git. If it leaks, revoke the key first.
- Project: the cluster is now a file, `k8s/kind-config.yaml`, so one command rebuilds it. ADR-002 says why I chose kind.

## Lesson 11 — Pods (2026-11-03)
- Learned: a Pod is the smallest thing Kubernetes runs, the kubelet starts it, and a deleted Pod stays gone.
- Broke: `/tasks` failed inside the cluster with `KeyError: 'DB_HOST'`. The Pod has no database settings yet.
- Fixed: found the Python error with `kubectl logs`. The database comes to Kubernetes in a later lesson.
- Security note: with no rules, a Pod runs as whatever user its image says, can reach every other Pod, and gets a ServiceAccount token.
- Project: the API runs on Kubernetes from my own manifest, `k8s/api-pod.yaml`.