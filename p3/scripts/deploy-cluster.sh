#!/usr/bin/env bash
set -euo pipefail

# Color definitions
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m"  # No Color / reset

log_info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
log_success() { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1" >&2; }

install_docker() {
  log_info "Installing Docker…"
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  sudo usermod -aG docker "$USER"
  log_success "Docker installed"
}

install_k3d() {
  log_info "Installing k3d (Kubernetes in Docker CLI)…"
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
  log_success "k3d installed"
}

install_kubectl() {
  log_info "Installing kubectl (Kubernetes CLI)…"
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
  log_success "kubectl installed"
}

create_cluster_and_namespaces() {
  log_info "Creating k3d cluster 'p3'…"
  k3d cluster create p3
  log_success "k3d cluster created"

  log_info "Creating namespaces: argocd and dev"
  kubectl create namespace argocd
  kubectl create namespace dev
  log_success "Namespaces created"
}

install_argocd() {
  log_info "Installing ArgoCD into namespace 'argocd'…"
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

  log_info "Waiting for ArgoCD server to be ready…"
  # kubectl -n argocd rollout status deployment/argocd-server --timeout=120s
  kubectl wait deployment/argocd-server -n argocd --for=condition=Available --timeout=300s

  log_success "ArgoCD installed"
}

configure_argocd_and_deploy_app() {
  log_info "Logging into ArgoCD server…"
  kubectl port-forward svc/argocd-server -n argocd 8080:443 &
  sleep 5

  ADMIN_PW=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

  argocd login localhost:8080 --insecure --username admin --password $ADMIN_PW
  log_success "Logged into ArgoCD server"

  log_info "Changing ArgoCD admin password…"
  argocd account update-password \
    --current-password $ADMIN_PW \
    --new-password "incept123!"
  log_success "ArgoCD admin password changed"

  log_info "Applying updated argocd-cm ConfigMap…"
  kubectl apply -f ../confs/argocd-cm.yaml -n argocd
  log_success "Updated argocd-cm applied"

  log_info "Applying ArgoCD Application manifest…"
  kubectl apply -f ../confs/application.yaml -n argocd
  log_success "ArgoCD Application manifest applied"
}

wait_and_portforward_app() {
  log_info "Waiting for service 'wil-playground' in namespace 'dev'…"
  until kubectl get svc wil-playground -n dev &>/dev/null; do
    log_warn "Service not created yet — waiting..."
    sleep 3
  done

  # log_info "Waiting for at least one pod with label app=wil-playground to be ready…"
  # kubectl wait pod -n dev -l app=wil-playground --for condition=Ready --timeout=60s
  # log_success "Service and pod are ready"

  log_info "Starting port-forward to svc/wil-playground → localhost:8888…"
  while true; do
    echo "--- Port-forwarding svc/wil-playground → localhost:8888 ---"
    kubectl port-forward svc/wil-playground -n dev 8888:8888 &
    log_warn "Port-forward died — restarting in 5s"
    sleep 5
  done
}

main() {
  # install_docker
  install_k3d
  # install_kubectl
  create_cluster_and_namespaces
  install_argocd
  configure_argocd_and_deploy_app
  wait_and_portforward_app
}

main

