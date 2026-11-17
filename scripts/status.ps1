# status.ps1: the first look at TaskBoard when something feels wrong. It only reads, it changes nothing.
$ns = "taskboard"
kubectl config use-context kind-taskboard

Write-Host "`n== 1. Nodes =="
kubectl get nodes

Write-Host "`n== 2. Pods =="
kubectl get pods -n $ns -o wide

Write-Host "`n== 3. Restarts and last exit code =="
kubectl get pods -n $ns -o custom-columns="POD:.metadata.name,RESTARTS:.status.containerStatuses[*].restartCount,LAST_EXIT:.status.containerStatuses[*].lastState.terminated.exitCode,REASON:.status.containerStatuses[*].lastState.terminated.reason"

Write-Host "`n== 4. Pods behind each Service =="
kubectl get endpointslices -n $ns

Write-Host "`n== 5. Warnings, newest last =="
kubectl get events -n $ns --field-selector type=Warning --sort-by=.lastTimestamp

Write-Host "`n== 6. Drift: lines that differ from the files (nothing = good) =="
$env:PATH += ";C:\Program Files\Git\usr\bin"
kubectl diff -f "$PSScriptRoot\..\k8s" | Select-String "^[-+] " | Select-String -NotMatch "generation:"
