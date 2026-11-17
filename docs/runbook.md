# TaskBoard runbook

What to do when TaskBoard misbehaves. Read-only steps first; change nothing until you know the cause.

## 1. First look (1 minute)

```powershell
.\scripts\status.ps1
```

It prints, read-only: nodes, Pods, restarts with the last exit code and reason, the Pods behind each Service (EndpointSlices), the `Warning` events of the last hour, and **drift**: the lines where the cluster differs from `k8s\` (empty = good).

Drift has 2 blind spots: objects that are not in `k8s\` (the Secret) and fields **added** by hand (`apply` and `diff` don't see them). For those, read `managedFields`: `kubectl get deploy <name> -n taskboard --show-managed-fields -o yaml`. A manager called `kubectl-set`, `kubectl-patch` or `kubectl-edit` means a hand change.

## 2. The debugging ladder

| Step | Command | Use it for |
|------|---------|------------|
| Look | `kubectl get pods -n taskboard` | `STATUS`, `READY`, `RESTARTS` |
| Read the file | `kubectl describe pod <pod> -n taskboard`, `kubectl get events -n taskboard --sort-by=.lastTimestamp` | `State`, `Last State` (reason, exit code), events. Events live about 1 hour |
| Listen | `kubectl logs <pod> -n taskboard --previous --timestamps` | Last words of a container that died. Times are UTC |
| Go inside | `kubectl exec -it -n taskboard deploy/taskboard-web -- sh` | The web image has `sh`, `wget`, `nc` |
| Bring tools | `kubectl debug -it <api-pod> -n taskboard --image=busybox:1.37 --target=api --container=toolbox -- sh` | The API image has no `nc`, `wget`, `nslookup`, `ps` |

Never started → the cause is in the events. Started and died → the cause is in the logs.

## 3. Known cases

| Symptom | Cause | Action |
|---------|-------|--------|
| Every Pod has 1+ restarts, API `LAST_EXIT 255` / `Unknown` | The laptop or Docker Desktop stopped. Containers were cut | None. Normal after a cold start |
| Web Pods restart a few times after a cold start, previous logs say `host not found in upstream "api"` | nginx started before the cluster DNS answered | None. Kubernetes restarts it until DNS is ready |
| Page loads, tasks fail with 502, all Pods `1/1` | The `api` Service selects no Pod (empty EndpointSlice) | Check the selector, re-apply `k8s\api-service.yaml` |
| API "can't reach the database" | DNS, Service or network | In the API toolbox: `nc -zv db 5432`, `nslookup db.taskboard.svc.cluster.local` |
| New API Pod `ImagePullBackOff`, events say `not found`, users see nothing | The image tag doesn't exist. `maxUnavailable: 0` keeps the old Pods serving | Check the tag on Docker Hub, then `.\scripts\up.ps1` (or `kubectl rollout undo`) |
| API Pods `CreateContainerConfigError`, `secret "db-secret" not found`, page 502 | The Secret was deleted. It's not in `k8s\`, so drift shows nothing | `.\scripts\up.ps1` rebuilds it from `secrets\db.env` |
| New Pod `Pending`, `FailedScheduling ... didn't match Pod's node affinity/selector`, `apply` says `unchanged` | A `nodeSelector` added by hand. `apply` can't remove a field it never set | `kubectl rollout undo deploy/<name> -n taskboard`, then find who added it (`managedFields`) |
| `CrashLoopBackOff`, `LAST_EXIT 137`, `REASON OOMKilled` | The memory limit is too low | Compare the limit with `k8s\`, then `.\scripts\up.ps1` |
| A backup Job hours late, first try `could not translate host name "db"`, second try OK | The laptop was off at 02:00, the CronJob ran at start-up before DNS was ready | None, if a full `.sql.gz` exists. A `.part` file = a failed try, never a backup |

## 4. Toolbox check of the API

Inside the toolbox (step "Bring tools"):

```sh
ps                                        # gunicorn runs as user 10001
wget -qO- localhost:5000/health           # {"status":"ok","version":"0.2"}
nc -zv db 5432                            # db (...:5432) open
nslookup db.taskboard.svc.cluster.local   # the Service IP
```

An ephemeral container can't be removed: delete that API Pod afterwards, its ReplicaSet makes a clean one.

## 5. Rules

- Fix the **file**, then `.\scripts\up.ps1`. Never fix inside a running container (lost at restart, drift from Git).
- After any investigation, `.\scripts\up.ps1` must answer `unchanged` everywhere.
- `exec` and `debug` read the database password and the ServiceAccount token. Use them last, and only on this lab cluster.
