# ADR-003: Use Helm to install other people's apps

- **Status:** Accepted
- **Date:** 2026-11-22

## Context

TaskBoard runs from 12 YAML files in `k8s\`, applied with `kubectl apply`. That works for my own app. But the next phases add apps that other people wrote: Traefik, cert-manager, Sealed Secrets, Argo CD. Each one is dozens of YAML files that change with every release. Copying them by hand is slow, and it's easy to get wrong.

## Decision

Install third-party apps with **Helm** (v4), from a values file kept in Git. The first one is the test release `demo` (podinfo 6.17.0) in the namespace `helm-test`, with its values in `helm-test/podinfo-values.yaml`.

Rules for every chart:

- Take the repository URL from the project's own docs, on `https://`.
- Pin `--version` on every install and every upgrade.
- Read the rendered YAML (`helm template`) before installing: `privileged`, `hostPath`, `ClusterRole`, images, hooks.
- Keep **all** my values in one file and always pass it with `-f`. Use one command: `helm upgrade --install`.
- Add TaskBoard's own rules in that file: non-root with a fixed number, `drop: ["ALL"]`, no privilege escalation, limits, spread over the nodes.
- Never pass a password as a value.

## Why

- **One command** installs, upgrades or rolls back every object of an app at once (`helm rollback`).
- **History in the cluster:** each revision is saved, so I can see what changed and go back.
- **Values in one file:** the settings live in Git, not in someone's terminal history.
- **It's the standard.** Most projects publish a Helm chart, and job postings ask for it.

## What we give up

- **I trust someone else's code.** A chart runs with my rights (cluster-admin on kind). Pinning and reading it lowers that risk, but doesn't remove it.
- **Defaults aren't safe by default.** podinfo ships `securityContext: {}`. I must add my rules myself, for every chart.
- **A trap with values.** An upgrade with *some* values drops all the old ones. I saw it live: in practice, one `--set replicaCount=1` wiped the message and the colour, and later a values file without `replicaCount` left 1 Pod instead of 3.
- **Release Secrets hold every value** of every revision. Anyone who can read Secrets in the namespace can read them.

## If this changes

Signed charts (Cosign, lesson 90) and a linter in CI (kube-linter, lesson 29) will make the checks automatic. TaskBoard itself gets its own chart in lesson 28.
