# ADR-002: Use kind for the local Kubernetes cluster

- **Status:** Accepted
- **Date:** 2026-11-02

## Context

TaskBoard needs a Kubernetes cluster to learn on and test with. The project has no budget, and it runs on one Windows laptop with Docker Desktop.

## Decision

Use **kind** (Kubernetes in Docker). The cluster is described in `k8s/kind-config.yaml`: 1 control-plane node and 2 worker nodes.

## Why

- It's real Kubernetes, running on Docker, which I already use.
- It's easy to test with. One command builds the cluster, and one deletes it.
- It's free. A cloud cluster costs money for every hour it runs.

## What we give up

All 3 nodes are containers on one laptop, so they aren't really separate machines.

- **One failure stops everything.** If the laptop or Docker stops, all 3 nodes stop together. A real cluster keeps running when one machine dies.
- **Size is limited** by the laptop's RAM and CPU.
- **Only this laptop can use it.** It isn't open to real users.
- **Nothing runs when the laptop is off.**

So kind is good for learning and testing, but not for production.

## If this changes

The app files stay normal Kubernetes files, so they can move to a real cluster later.
