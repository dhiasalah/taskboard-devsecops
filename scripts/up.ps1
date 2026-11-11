# up.ps1: build TaskBoard on a kind cluster, from zero, with one command.
Set-Location (Split-Path $PSScriptRoot)

if (-not (Test-Path "secrets\db.env")) {
    throw "secrets\db.env is missing. Make it first (lesson 16)."
}

if ((kind get clusters) -notcontains "taskboard") {
    kind create cluster --config cluster\kind-config.yaml
    if ($LASTEXITCODE -ne 0) { throw "kind could not create the cluster" }
}
kubectl config use-context kind-taskboard
kubectl config set-context --current --namespace=taskboard

kubectl apply -f k8s\namespace.yaml
kubectl create secret generic db-secret -n taskboard --from-env-file=secrets\db.env --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f k8s\

Write-Host "Waiting for TaskBoard to be ready..."
kubectl wait deployment --all -n taskboard --for=condition=Available --timeout=180s
if ($LASTEXITCODE -ne 0) { throw "TaskBoard is not ready. Try: kubectl get pods -n taskboard" }

kubectl get pods -n taskboard
Write-Host "TaskBoard is up. Open it with: kubectl port-forward -n taskboard svc/web 8080:80"
