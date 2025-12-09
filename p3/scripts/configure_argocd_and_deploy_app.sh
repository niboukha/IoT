#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")"
source "./colors.sh"

info    "Logging into ArgoCD server…"
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

argocd login localhost:8080 --insecure --username admin --password "$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
success "Logged into ArgoCD server"

argocd account update-password --current-password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d) --new-password "incept123!"
success "ArgoCD admin password changed"

info    "Applying updated argocd-cm ConfigMap…"
kubectl apply -f ../confs/argocd-cm.yaml -n argocd
success "Updated argocd-cm applied"

info    "Applying ArgoCD Application manifest…"
kubectl apply -f ../confs/application.yaml -n argocd
success "ArgoCD Application manifest applied"
