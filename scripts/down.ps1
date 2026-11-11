# down.ps1: delete the TaskBoard cluster. Files and secrets\db.env stay.
kind delete cluster --name taskboard
kubectl config use-context sentinel
