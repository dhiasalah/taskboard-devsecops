# Security gaps (risk register)

What is still insecure in TaskBoard, found by a small audit on the running kind cluster
(lesson 19, 2026-11-11). Each gap has the lesson that will fix it. Written down on purpose:
known gaps with a plan are **security debt**, not surprises.

| # | Gap | How I checked | Risk | Fixed in |
|---|-----|---------------|------|----------|
| 1 | Any Pod in any namespace can reach Postgres on port 5432 | `nc -zv db 5432` from a web Pod, and `nc -zv db.taskboard 5432` from a Pod in `default`: both `open` | 🔴 An attacker in any Pod can try to log into the database | Lesson 37 (NetworkPolicies) |
| 2 | Postgres runs as **root** | `kubectl exec taskboard-db-0 -- id` → `uid=0(root)` | 🔴 A bug in Postgres gives root inside the container, closer to the node | Lessons 26 and 38 (securityContext, `runAsNonRoot`) |
| 3 | Every Pod carries a ServiceAccount token it never uses | `/var/run/secrets/kubernetes.io/serviceaccount/token` exists in the API Pod. `can-i get secrets` = `no` today | 🟠 A stolen badge is a free key to the API server, and one wrong RBAC rule later makes it powerful | Lesson 36 (RBAC, `automountServiceAccountToken: false`) |
| 4 | The cluster accepts privileged Pods | `kubectl run evil --privileged --dry-run=server` → `pod/evil created (server dry run)` | 🔴 A privileged Pod has almost the power of the node | Lesson 38 (Pod Security Standards), later Kyverno (lesson 93) |
| 5 | The DB password sits in the API's environment variables | `env \| cut -d= -f1` in an API Pod lists `POSTGRES_PASSWORD` | 🟠 Anyone who can `exec` into the API, or read a crash dump, sees it | Lessons 39 (Sealed Secrets), 95–96 (Vault + External Secrets), 100 (encryption at rest) |
| 6 | My own user is `cluster-admin` | `kubectl auth can-i '*' '*'` → `yes` | 🟠 A leaked kubeconfig = the whole cluster | Lesson 36 (RBAC) |
| 7 | No HTTPS: traffic is plain HTTP | The app is reached with `http://localhost:8080` through `port-forward` | 🟡 Anyone on the path can read and change traffic | Lessons 31–35 (Traefik, cert-manager) |
| 8 | Images are not signed, and the API has 5 HIGH CVEs accepted in v0.1 | Trivy scan (lesson 08). Nothing checks an image before it runs | 🟠 A swapped or old vulnerable image would run without a warning | Lessons 87, 90, 94 (CI gate, Cosign, verify signatures) |
| 9 | The database backups are on the **same laptop** as the data, and **not encrypted** (found in lesson 23) | `docker exec <node> sh -c 'zcat /var/local-path-provisioner/*_taskboard_db-backups/*.gz'` prints every task, with no password | 🔴 One theft, disk failure or ransomware takes the data and its backups. Anyone who reaches the node or mounts the PVC reads the whole database | Lesson 60 (Velero + MinIO: off-site, encrypted) |
| 10 | The backup Pod runs as **root** and uses the database **owner's** password (found in lesson 23) | The backup file is owned by `root root`, and `PGPASSWORD` comes from `db-secret` | 🟠 A backup only needs to read. A bug in this Pod could change or drop the data | Lessons 26 (non-root) and 36 (least privilege) |

## Attack path today

A bug in the web page → reach the database port (gap 1) → get into an API Pod → read the
password from `env` (gap 5) → log into Postgres. Each step is small, together they are a full
break-in (**lateral movement**). That's why the plan adds many small locks (**defense in depth**).

## Already locked ✅

- api and web run as non-root, and the API can't rewrite its own code
- Images are pinned by digest (`name@sha256:...`), so a moved tag can't change what runs
- Every container has requests and limits, plus a LimitRange, so a DoS stays inside one container
- Probes heal a frozen container
- The DB password is random, Git-ignored (`secrets/`), and never typed on a command line
- Every Service is ClusterIP (or headless): nothing is open on my network, and the database has no door to the outside
- Postgres is a StatefulSet with its own disk: the tasks survive a Pod restart
- A CronJob backs up the database every night to a separate volume, keeps 7 days, and fails loudly (`set -eo pipefail`)
- A restore-test Job proved that a backup can be loaded, with the backups mounted read-only
