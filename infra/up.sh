#!/usr/bin/env bash
# Creates the EKS cluster, installs Argo CD and points it at this repo.
set -euo pipefail
cd "$(dirname "$0")/.."

for c in aws eksctl kubectl; do
  command -v "$c" >/dev/null || { echo "Missing $c. Install it first."; exit 1; }
done
aws sts get-caller-identity >/dev/null || { echo "No AWS credentials. Run: aws login"; exit 1; }

eksctl create cluster -f infra/cluster.yaml

echo "Installing Argo CD (${ARGOCD_VERSION:-stable})…"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd --server-side --force-conflicts \
  -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION:-stable}/manifests/install.yaml"
kubectl wait --for=condition=Established crd/applications.argoproj.io --timeout=120s

# Poll Git every 30s instead of 3 min. The deck's bridge also requests a refresh on every commit.
kubectl -n argocd patch configmap argocd-cm --type merge -p '{"data":{"timeout.reconciliation":"30s"}}'
kubectl -n argocd rollout restart statefulset argocd-application-controller
kubectl -n argocd rollout status statefulset argocd-application-controller --timeout=300s
kubectl -n argocd rollout status deploy argocd-repo-server --timeout=300s

kubectl apply -f argocd/application.yaml

echo "Waiting for Argo CD to create deploy/color-block…"
until kubectl -n demo get deploy color-block >/dev/null 2>&1; do sleep 3; done
kubectl -n demo rollout status deploy color-block --timeout=300s

echo
echo "Ready. Argo CD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
echo "Argo CD UI:  kubectl -n argocd port-forward svc/argocd-server 8080:443   →  https://localhost:8080"
