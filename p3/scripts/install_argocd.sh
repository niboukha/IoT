#!/usr/bin/env bash
set -eu
source "$(dirname "$0")/colors.sh"

info    "Installing ArgoCD into namespace 'argocd'…"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

info    "Waiting for ArgoCD server deployment to be ready…"
kubectl -n argocd rollout status deployment/argocd-server --timeout=120s

# kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=120s

success "ArgoCD installed"
