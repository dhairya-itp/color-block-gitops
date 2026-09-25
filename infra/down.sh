#!/usr/bin/env bash
# Deletes the demo app and the whole EKS cluster.
set -euo pipefail
cd "$(dirname "$0")/.."
kubectl -n argocd delete application color-block --wait --timeout=120s || true
eksctl delete cluster -f infra/cluster.yaml --wait
