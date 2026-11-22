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
## Lesson 19 — TaskBoard on Kubernetes (2026-11-11)
- Learned: `kubectl apply` is idempotent (run it twice, nothing breaks), `kubectl create` is not (`AlreadyExists`). `create ... --dry-run=client -o yaml | kubectl apply -f -` makes the Secret safe to run twice.
- Built: `scripts/up.ps1` builds TaskBoard from zero (cluster, namespace, Secret, app, then waits for the probes) and `scripts/down.ps1` removes it. I deleted my cluster and rebuilt it with one command: 6 Pods ready.
- Mixed up again: the scheduler only adds up **requests** to pick a node. A 2 CPU limit doesn't stop a Pod that asks for 500m from fitting in 1 CPU of room.
- Security note: a small audit found 8 open doors (any Pod reaches the db, root in the db, a ServiceAccount token in every Pod, privileged Pods allowed, the password in env vars, I am cluster-admin, no HTTPS, unsigned images). Small gaps chain into a break-in, so I wrote them down with the lesson that fixes each one: `docs/security-gaps.md`.
- Project: README "Run on Kubernetes", and `kind-config.yaml` moved to `cluster/` so `k8s/` only holds Kubernetes objects.
## Lesson 20 — Checkpoint + v0.2 (2026-11-11)
- Learned: I finally saw it live. A Pod with a 20-CPU **limit** ran on an 8-CPU node, and a Pod **requesting** 20 CPU stayed `Pending`. The scheduler only counts requests.
- Learned: the CKA exam is 2 hours in a real terminal. The speed tricks are making YAML with `--dry-run=client -o yaml`, `kubectl explain`, and switching to the right context for every task.
- Fix-it drill: 3 bugs in a broken app (a tag typo → `ImagePullBackOff`; a Service selector that matched no Pod → empty EndpointSlice; a wrong `targetPort`). Bugs 2 and 3 gave the same `Connection refused`, and only the EndpointSlice told them apart.
- Security note: an image inventory lists every image running in the cluster. My 3 images are pinned by digest, and the 8 system images use tags. When a CVE comes out, the inventory answers "are we hit?" in a minute.
- Project: 🏷️ **v0.2 — Runs on Kubernetes** released, with the image digests in the release notes.
## 🎓 Phase 1 exams (2026-11-11)
- QCM: 19/20 on the first try. The one I missed: without `secrets/db.env`, kind still builds the cluster fine. Only the Secret is missing, so the api and db Pods sit in `CreateContainerConfigError` until `kubectl wait` gives up.
- Lab "Monday on call": I got stuck and stopped. I learned the method from the solution: symptom → the one command that shows the cause → fix → test again.
- Lab retake "Tuesday on call": passed, all 6 checks. I found 4 planted faults: a wrong DB password in the Secret (fixed from my file, then `rollout restart`, because env vars are only read at start), a fake ReplicaSet `api-canary` stealing `/api/health` traffic with my api's label (deleting its Pod did nothing: I had to delete the ReplicaSet that owns it), a db memory limit above the LimitRange (the ReplicaSet said `forbidden`), and a `node-agent` Deployment in a `monitoring` namespace that mounted the whole node disk.
- Broke: I re-made the Secret by hand with the wrong password. Fixed: let `up.ps1` build it from `secrets/db.env`, never type a secret by hand.
- Security note: `kubectl apply` only adds and changes what is in my files. It never removes an intruder. Someone has to look for extra things: an image inventory over all namespaces, and the owner of every Pod.
## Lesson 21 — Storage: PV, PVC, StorageClass (2026-11-13)
- Learned: a container's own files die with it. A PVC is my request for a disk, the StorageClass is the supplier, and the PV is the real disk, made automatically and Bound to my PVC. A Pod says which PVC with `volumes` and which folder with `volumeMounts`.
- Saw it live: I deleted the db Pod and `/api/tasks` answered `[]`. After the PVC, the same test kept my task.
- Learned: `ReadWriteOnce` means one **node**, not one Pod. So the database uses `strategy: Recreate`: never two Postgres servers on the same files.
- Finally clear: a missing Secret doesn't stop the cluster. The Pod is accepted, then sits in `CreateContainerConfigError`.
- Security note: a volume on kind is a plain folder on a node, mode `777`, not encrypted. With `docker exec` on the node I found my task title in Postgres's files. Anyone with node access or a `hostPath` Pod can do the same.
- Project: `k8s/db-pvc.yaml` (1Gi) is mounted at `/var/lib/postgresql`. Tasks survive a Pod restart, but not a cluster delete: that needs backups.
## Lesson 22 — StatefulSets (2026-11-15)
- Learned: web and api are stateless (any copy will do), a database is stateful. A StatefulSet gives each Pod a fixed name (`taskboard-db-0`), its own PVC made from `volumeClaimTemplates` (`data-taskboard-db-0`), and an order (start 0, 1, 2; stop 2, 1, 0).
- Saw it live: I deleted `shop-1` and it came back with the same name and the same file, only a new IP. A headless Service (`clusterIP: None`) gives each Pod its own DNS name.
- Asked myself: with 3 copies and 3 disks, can two tasks get the same id? Yes. Kubernetes never copies data between the disks, so `replicas: 3` gives 3 separate databases. Real setups use replication: one primary takes the writes, the replicas copy it and are read-only. The fixed names are what make that possible (everyone knows who `-0` is).
- Security note: a database gets a ClusterIP or headless Service, never a NodePort or LoadBalancer. `port-forward` listens on `127.0.0.1` only; with `--address 0.0.0.0` it is offered to the whole Wi-Fi. PVCs stay behind when a StatefulSet is deleted: forgotten PVCs are forgotten data.
- Project: Postgres moved from a Deployment to a StatefulSet with a dump (`pg_dump`) and a restore (`psql -f`). No task was lost, and the dump was deleted after. `up.ps1` now also waits for the StatefulSet.
## Lesson 23 — DaemonSets, Jobs & CronJobs (2026-11-15)
- Learned: 3 more ways to run Pods. A DaemonSet puts one Pod on every node (it skipped my control-plane because of its taint). A Job runs a task until it ends: `0/1 Completed` is a success. A CronJob is a clock that makes Jobs: `0 2 * * *` = every day at 02:00.
- Saw it live: a Job that always fails made 3 Pods in `Error` (1 try + 2 retries), then gave up with `BackoffLimitExceeded`. Deleting a CronJob removes its Jobs and their Pods (owner chain).
- Mixed up: a Job without a `restartPolicy` line is refused by the API server (only `OnFailure` or `Never`). And a CronJob without `timeZone` thinks in UTC: `0 2 * * *` would run at 03:00 on my watch in winter.
- Security note: a backup is a life jacket and a second copy of everything worth stealing. I read my own backup from the node with `zcat`, with no password: `gzip` is not encryption. Without `set -o pipefail`, a failed `pg_dump` still gives a green Job and an empty file.
- Project: a nightly backup CronJob (`db-backup`, 02:00 Paris time, 7 days kept) writes to its own PVC, and a `restore-test` Job proved the backup loads into a scratch database. Still open: the backups are on the same laptop and not encrypted.
## Lesson 24 — Debugging toolkit (2026-11-16)
- Learned: a ladder instead of guessing. Look (`get pods`) → read the file (`describe`, events) → listen (`logs --previous`) → go inside (`exec`) → bring tools (`kubectl debug`). Never started = the answer is in the events; started and died = in the logs.
- Saw it live: the web Pods had restarted many times with nobody touching them. `describe` said exit 1 after 5 s, `logs --previous` said `host not found in upstream "api"`, at the minute Docker Desktop started. nginx was faster than the cluster DNS after a cold start; the API's `255 / Unknown` was the laptop shutting down. Not a bug, Kubernetes healed itself.
- Asked myself: why `--copy-to` makes a twin instead of debugging the original Pod? A crashing container is dead most of the time, and a Pod's command can't be changed once it exists. The twin has the same image and files but runs `sh`, so it stays alive, and the original stays untouched as evidence.
- Security note: one `exec` into the API can read the database password (I counted its 24 characters without printing it). `pods/exec` is a separate right from `pods/log`: I have it (cluster-admin), the Pods' ServiceAccount doesn't. A debug toolbox runs as root next to my non-root app.
- Project: `scripts/status.ps1` (read-only first look) and `docs/runbook.md`.
## Lesson 25 — k9s + classic failures (2026-11-17)
- Learned: k9s is the debugging ladder on one screen (`d` describe, `l` logs, `p` previous logs, `:events`). I start it with `--readonly`, so a wrong key can't delete anything.
- Broke and fixed TaskBoard 5 ways: a tag that doesn't exist (`ImagePullBackOff`, and users saw nothing thanks to `maxUnavailable: 0`), a deleted Secret (`CreateContainerConfigError`), a typo in a Service selector (every Pod `1/1`, no event, an empty EndpointSlice), a `nodeSelector` no node matches (`Pending`), and a 12Mi memory limit (exit 137, `OOMKilled`).
- Fell into the `apply` trap: a field added by hand survives `apply` and `kubectl diff`. Only `rollout undo` (or removing the field) fixed it. `managedFields` told me which tool changed it, and when.
- Security note: rebuilt a real timeline from my own cluster. The backup ran 8 hours late because the laptop was off at 02:00, the first try failed on DNS at start-up, and the `.part` name kept the broken file from looking like a good backup. Save the evidence before fixing: events only live about 1 hour, and no tool here says **who** did it (that's the audit log, later).
- Project: `scripts/status.ps1` got a 6th check, drift (`kubectl diff` against `k8s\`), and the 5 cases went into `docs/runbook.md`.
## Lesson 26 — Scheduling + securityContext (2026-11-18)
- Learned: how the scheduler picks a node. `nodeSelector` = "only nodes with this label", a taint = "keep out" on a node, a toleration = "I may go there" (it allows, it doesn't force). A spread rule (`topologySpreadConstraints`) keeps copies on different nodes.
- Two spread traps: without `nodeTaintsPolicy: Honor` the tainted control-plane counts as an empty node and Pods stay `Pending`; without `matchLabelKeys: [pod-template-hash]` the old Pods count during a rolling update and the new ones pile up on one node.
- Saw it live: `runAsNonRoot: true` alone isn't enough. busybox → `image will run as root`; my API image (`USER appuser`) → `non-numeric user`, so the badge needs a number (`runAsUser`). The rollout got stuck and `maxUnavailable: 0` kept the old Pods serving users.
- Security note: same Pod, same `hostPath` to the node's `/etc`: as root it could count the node's password file and had 14 capabilities (`CapEff a80425fb`); as UID 1000 with `drop: ["ALL"]` → `Permission denied`, `CapEff 0`. UID 0 in a container is UID 0 for the node's kernel.
- Project: every TaskBoard Pod is non-root with a fixed UID (api 10001, web 101, db + backup 70), `allowPrivilegeEscalation: false`, all capabilities dropped; web and api spread over both workers; `status.ps1` got a 7th check (non-root). Released **v0.3**.
## 🎓 Phase 2 exams (2026-11-18)
- QCM: 24/24 on the first try (storage, StatefulSets, Jobs and CronJobs, debugging, scheduling, securityContext, plus 4 questions from the lab).
- Lab: a broken TaskBoard to fix alone (a tainted node, a suspended backup CronJob, a stranger DaemonSet, drift). Passed on the retake, 5 of 6 criteria.
- Broke: twice I ran `kubectl delete -f k8s\` then `apply` to "reset" things. The folder holds the namespace and the PVCs, and kind's reclaim policy is `Delete`: the tasks and every old backup were gone. It looked fixed, but the original disk was lost.
- Learned: fix the field that drifted (`kubectl edit`/`patch`, `rollout restart`), never delete the whole folder. Before deleting a namespace, look inside: `kubectl get pvc -n <ns>`. A CronJob holds no data, so delete + re-apply of that one file was fine.
## Lesson 27 — Helm basics (2026-11-22)
- Learned: Helm is the package manager of Kubernetes. A chart is a box of templates with holes plus default values; my values fill the holes; one installed copy is a release with numbered revisions.
- Read before installing, without touching the cluster: `helm show chart`, `helm show values`, `helm template`. In podinfo I found no `privileged` or `hostPath`, but an empty `securityContext` and two risky test-hook images (one with no tag, one curl from 2020).
- Fell into the trap on purpose: `helm upgrade` with only `--set replicaCount=1` dropped the message and the colour. Then fell into it for real: my values file had no `replicaCount`, so the release ran 1 Pod instead of 3. Fixed in the file, not with `--set`.
- Security note: a chart runs with my rights, so I take the repo URL from the project's docs, pin `--version` on every command, and add my own rules (non-root 100/101, drop ALL, limits, spread). Every value lives in a release Secret for every revision: never a password in `--set`.
- Project: podinfo 6.17.0 runs in `helm-test` from `helm-test/podinfo-values.yaml`, one Pod per worker, `CapEff 0`. ADR-003 "why Helm".
