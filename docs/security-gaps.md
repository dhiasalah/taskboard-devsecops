# Security gaps (risk register)

What is still insecure in TaskBoard, found by a small audit on the running kind cluster
(lesson 19, 2026-11-11). Each gap has the lesson that will fix it. Written down on purpose:
known gaps with a plan are **security debt**, not surprises.

| # | Gap | How I checked | Risk | Fixed in |
|---|-----|---------------|------|----------|
| 1 | Any Pod in any namespace can reach Postgres on port 5432 | `nc -zv db 5432` from a web Pod, and `nc -zv db.taskboard 5432` from a Pod in `default`: both `open` | 🔴 An attacker in any Pod can try to log into the database | Lesson 37 (NetworkPolicies) |
| 2 | Postgres runs as **root** | `kubectl exec deploy/taskboard-db -- id` → `uid=0(root)` | 🔴 A bug in Postgres gives root inside the container, closer to the node | Lessons 26 and 38 (securityContext, `runAsNonRoot`) |
| 3 | Every Pod carries a ServiceAccount token it never uses | `/var/run/secrets/kubernetes.io/serviceaccount/token` exists in the API Pod. `can-i get secrets` = `no` today | 🟠 A stolen badge is a free key to the API server, and one wrong RBAC rule later makes it powerful | Lesson 36 (RBAC, `automountServiceAccountToken: false`) |
| 4 | The cluster accepts privileged Pods | `kubectl run evil --privileged --dry-run=server` → `pod/evil created (server dry run)` | 🔴 A privileged Pod has almost the power of the node | Lesson 38 (Pod Security Standards), later Kyverno (lesson 83) |
| 5 | The DB password sits in the API's environment variables | `env \| cut -d= -f1` in an API Pod lists `POSTGRES_PASSWORD` | 🟠 Anyone who can `exec` into the API, or read a crash dump, sees it | Lessons 39 (Sealed Secrets), 85–86 (Vault + External Secrets), 90 (encryption at rest) |
| 6 | My own user is `cluster-admin` | `kubectl auth can-i '*' '*'` → `yes` | 🟠 A leaked kubeconfig = the whole cluster | Lesson 36 (RBAC) |
| 7 | No HTTPS: traffic is plain HTTP | The app is reached with `http://localhost:8080` through `port-forward` | 🟡 Anyone on the path can read and change traffic | Lessons 31–35 (Traefik, cert-manager) |
| 8 | Images are not signed, and the API has 5 HIGH CVEs accepted in v0.1 | Trivy scan (lesson 08). Nothing checks an image before it runs | 🟠 A swapped or old vulnerable image would run without a warning | Lessons 77, 80, 84 (CI gate, Cosign, verify signatures) |

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
- Every Service is ClusterIP: nothing is open on my network
