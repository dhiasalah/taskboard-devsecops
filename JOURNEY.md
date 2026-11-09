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
## Lesson 12 — Manifests, namespaces, labels & selectors (2026-11-03)
- Learned: every manifest has `apiVersion`, `kind`, `metadata` and `spec`, and the cluster writes `status`. Namespaces are rooms, and labels are stickers that selectors pick.
- Broke: in the exercise, I wasn't sure which Pods a label change and a delete by label would leave.
- Fixed: a label is just a sticker on a running Pod. Change it, and the selector sees the new value at once.
- Security note: a namespace is not a wall. A Pod in another namespace still reached my API. But it's the scope where rights, quotas and network rules attach later, and deleting one deletes everything inside it.
- Project: TaskBoard has its own `taskboard` namespace, and the API wears the standard `app.kubernetes.io/` labels.
## Lesson 13 — ReplicaSets & Deployments (2026-11-03)
- Learned: a Deployment makes a ReplicaSet, and the ReplicaSet keeps the right number of Pods, counting them by label. The file's `replicas` wins over `kubectl scale`.
- Broke: the web Pods crash with `host not found in upstream "api"`. nginx looks for `api`, a Compose name that doesn't exist in Kubernetes yet.
- Fixed: found it with one `kubectl logs deployment/taskboard-web`. The fix (a Service called `api`) comes in lesson 15.
- Surprise: I stopped a node. It said `NotReady`, but its Pod still said `Running`. The status was old news: the dead node couldn't report anymore.
- Security note: every tag can move, so both images are now pinned by digest. A tag hijack can't change what my cluster runs.
- Project: the API runs as 3 replicas and the web page as 2, as Deployments. The lone `api-pod.yaml` is gone.
## Lesson 14 — Rolling updates & rollbacks (2026-11-04)
- Learned: a rolling update makes a new ReplicaSet for the new version, grows it and shrinks the old one, a few Pods at a time. `maxSurge: 1` + `maxUnavailable: 0` means never fewer than 3 ready API Pods.
- Broke: `InvalidImageName`, because I typed the image as `dhiasalah\taskboard-api` with a Windows backslash. Image names always use `/`.
- Broke too: after `rollout undo --to-revision=3` I forgot to apply my file again, so the cluster ran v0.1 while the file said v0.2. That's drift.
- Fixed: read the error with my mentor and fixed the slash. Lesson 15 starts by spotting the drift and applying the file.
- Security note: in an incident, contain first (`rollout undo`, seconds), then investigate, then fix the file. A broken image gets stuck instead of taking the app down.
- Project: shipped API v0.2 (`/health` shows the version) with zero downtime, scanned before the push, pinned by digest, with a readable `CHANGE-CAUSE` history.
## Lesson 15 — Services & cluster DNS (2026-11-04)
- Learned: Pod IPs change, so a Service gives a group of Pods one stable name and IP, found by labels. CoreDNS turns `api` into that IP (`api.taskboard` from another namespace).
- Broke: the cluster still ran v0.1 from lesson 14's rollback, while my file said v0.2. Drift, again.
- Fixed: spotted it by comparing the file's image with the cluster's, then `kubectl apply` made the file win. Then the `api` Service fixed nginx's `host not found in upstream "api"`.
- Security note: NodePort opens the same port on every node, so I keep everything ClusterIP and use `port-forward`. A Service trusts labels, not people: an impostor Pod with the right label got real traffic.
- Project: TaskBoard has `api` and `web` Services. The web Pods run, the page opens in my browser, and `/api/health` goes laptop → web → api. `/api/tasks` still needs the database (lesson 16).
## Lesson 16 — ConfigMaps & Secrets (2026-11-07)
- Learned: settings live outside the image. A ConfigMap is for settings anyone may read, and a Secret is for private ones. `envFrom` turns every key into an env var, and env vars are only read when the container starts.
- Broke: on purpose, I set `DB_HOST: database`. Nothing broke until `rollout restart`, and then `/api/tasks` failed: no Service is called `database`.
- Fixed: put `db` back, applied, and restarted again. The ConfigMap value must match the Service name.
- Surprise: I deleted the Postgres Pod and my tasks were gone. There's no disk yet (lesson 21).
- Security note: a Secret is only base64, not encryption. Anyone who can `get secrets`, `exec` into a Pod, copy etcd or see the YAML can read it. So the password is random, lives in a Git-ignored `secrets/` folder, and never goes through `--from-literal`.
- Project: TaskBoard runs fully on Kubernetes: web → api → db, with a `db-config` ConfigMap, a `db-secret` Secret and a `db` Service.
## Lesson 17 — Probes (2026-11-08)
- Learned: 3 probes ask 3 questions. Startup: "are you up yet?". Readiness: "can you take traffic?" (fail = out of the Service, no restart). Liveness: "are you still alive?" (fail = restart).
- Mixed up: I thought `pg_isready` fits a `tcpSocket` probe. It's a command run inside the container, so it's an `exec` probe (exit code 0 = OK). A TCP probe only checks that the port opens.
- Security note: availability is security. A frozen app is healed by its liveness probe. But a liveness probe must never check the database, or a DB outage restarts every API Pod at once.
- Project: all 3 TaskBoard parts have probes: the API and web page on HTTP, Postgres with `pg_isready` (startup + readiness) and a TCP check on 5432 (liveness). All 6 Pods are `1/1`.
## Lesson 18 — Requests, limits & QoS (2026-11-09)
- Learned: a request is what a container is promised, and a limit is the most it may use. Above the CPU limit it's slowed down (throttled). Above the memory limit it's killed (`OOMKilled`, exit code 137).
- Mixed up: I thought the scheduler looks at limits. It only adds up **requests** to find a node with room.
- Security note: limits keep a DoS (an attacker or a memory leak) inside one container, so the db next to it survives. The `taskboard-limits` LimitRange gives forgotten containers defaults and refuses huge ones.
- Project: every TaskBoard container has requests and limits (api 50m/64Mi → 500m/256Mi, web 10m/16Mi → 200m/64Mi, db 100m/256Mi → 1/512Mi). All 6 Pods are Burstable.
