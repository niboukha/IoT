#!/usr/bin/env bash
set -eu
source "$(dirname "$0")/colors.sh"

info    "Waiting for service 'wil-playground' in namespace 'dev'…"
until kubectl get svc wil-playground -n dev 2>/dev/null; do
  warn "Service not created yet — waiting..."
  sleep 3
done

info    "Waiting for at least one pod with label app=wil-playground to be ready…"
kubectl wait pod -n dev -l app=wil-playground \
  --for condition=Ready --timeout=60s

success "Service and pod are ready"

info    "Starting port-forward to svc/wil-playground → localhost:8888…"
while true; do
  echo "--- Port-forwarding svc/wil-playground namespace dev → localhost:8888 ---"
  kubectl port-forward svc/wil-playground -n dev 8888:8888 &
  warn "Port-forward died — restarting in 5s"
  sleep 5
done
