#!/usr/bin/env bash
set -eu
source "$(dirname "$0")/colors.sh"

info    "Creating k3d cluster 'p3'…"
k3d cluster create p3
success "k3d cluster created"

info    "Creating namespaces: argocd, dev…"
kubectl create namespace argocd
kubectl create namespace dev
success "Namespaces created"
