#!/usr/bin/env bash
set -euo pipefail

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m"

log_info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
log_success() { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1" >&2; }

log_info "=== Starting k3d cluster deployment script ==="

install_docker() {
  log_info "Installing Docker…"
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  sudo chmod 666 /var/run/docker.sock
  log_success "Docker installed"
}

install_git() {
  log_info "Installing Git…"
  sudo apt-get update
  sudo apt-get install -y git
  log_success "Git installed"
}

install_k3d() {
  log_info "Installing k3d (Kubernetes in Docker CLI)…"
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
  log_success "k3d installed"
}

install_kubectl() {
  log_info "Installing kubectl (Kubernetes CLI)…"
  # curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
  # chmod +x kubectl
  # sudo mv kubectl /usr/local/bin/

  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/

  log_success "kubectl installed"
}

create_cluster_and_namespaces() {
  log_info "Creating k3d cluster 'bonus'…"
  k3d cluster create bonus
  log_success "k3d cluster created"

  log_info "Creating namespaces: argocd, gitlab and dev"
  kubectl create namespace argocd
  kubectl create namespace dev
  kubectl create namespace gitlab
  log_success "Namespaces created"
}

install_argocd() {
  log_info "Installing ArgoCD into namespace 'argocd'…"
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

  log_info "Waiting for ArgoCD server to be ready…"
  kubectl wait deployment/argocd-server -n argocd --for=condition=Available --timeout=300s

  log_success "ArgoCD installed"
}

install_argocd_client() {
  log_info "Installing ArgoCD CLI…"

  # curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-arm64
  curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
  chmod +x argocd
  sudo mv argocd /usr/local/bin/

  log_success "ArgoCD CLI installed"
}

deploy_gitlab() {
  log_info "Deploying GitLab with Helm…"

  log_info "Installing Helm…"
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  log_success "Helm installed"

  HOST_ENTRY="127.0.0.1 gitlab.k3d.gitlab.com"
  HOSTS_FILE="/etc/hosts"
  if grep -q "$HOST_ENTRY" "$HOSTS_FILE"; then
    log_info "Hosts entry already exists"
  else
    log_info "Adding hosts entry for GitLab"
    echo "$HOST_ENTRY" | sudo tee -a "$HOSTS_FILE" >/dev/null
  fi

  log_info ""
  helm repo add gitlab https://charts.gitlab.io/
  helm repo update

  log_info "Installing GitLab chart…"
  helm upgrade --install gitlab gitlab/gitlab \
    -n gitlab \
    -f https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml \
    --set global.hosts.domain=k3d.gitlab.com \
    --set global.hosts.externalIP=0.0.0.0 \
    --set global.hosts.https=false \
    --set global.gitlabEdition=ce \
    --timeout 600s

  log_success "GitLab chart installed"

  log_info "Waiting for GitLab webservice to be ready…"
  until kubectl get pods -n gitlab -l app=webservice \
    -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' \
    | grep -q True; do
      log_info "Waiting for GitLab webservice..."
      sleep 40
  done

  log_success "GitLab webservice is ready"

  log_info ""
  GITLAB_PASS=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode)
  log_success "GitLab installed and ready"

  log_info "Port‑forwarding GitLab UI at http://localhost:8083…"
  kubectl port-forward -n gitlab svc/gitlab-webservice-default 8083:8181 &

  log_info "Waiting for GitLab web UI to start…"
  until curl -s http://gitlab.k3d.gitlab.com:8083/ > /dev/null; do
    echo "Waiting for GitLab to be reachable…"
    sleep 5
  done
  log_success "GitLab web UI is reachable."

  log_info -e "\nGitLab credentials:"
  log_info "Username: root"
  log_info "Password: $GITLAB_PASS"

  log_info "Configuring Git to talk to GitLab…"
  cat <<EOF > "$HOME/.netrc"
machine gitlab.k3d.gitlab.com
login root
password $GITLAB_PASS
EOF
  chmod 600 "$HOME/.netrc"
  log_success "Git configured"

  git config --global user.email "nisrinboukhari19@gmail.com"
  git config --global user.name "niboukha"


  SCRIPT_DIR=$(pwd)
  log_info "PRINTING SCRIPT_DIR----------------: $SCRIPT_DIR"

  log_info "Initializing local Git repo and pushing to GitLab…"
  cd "$HOME/Desktop/shichamGitlab" || log_error "Repo directory not found"
  git init
  git add .
  git commit -m "first commit"
  git push --set-upstream "http://gitlab.k3d.gitlab.com:8083/root/shicham.git" master

  log_info "Generating GitLab Personal Access Token…"
  TOOLBOX_POD=""
  while [ -z "$TOOLBOX_POD" ]; do
    TOOLBOX_POD=$(kubectl get pods -n gitlab -l app=toolbox -o jsonpath='{.items[0].metadata.name}')
    sleep 3
  done

  kubectl exec -n gitlab "$TOOLBOX_POD" -- bash -lc "\
    gitlab-rails runner '\
    user = User.find_by(username: \"root\"); \
    token = user.personal_access_tokens.create!(name: \"cli-token\", scopes: [:api], expires_at: 365.days.from_now.to_date); \
    token.set_token(\"mysecuretoken1234567890\"); \
    token.save!; \
    puts token.token \
    ' " > /tmp/gitlab_pat.txt

  PAT=$(tail -n1 /tmp/gitlab_pat.txt | tr -d '\r\n')
  log_success "Created PAT: $PAT"

  log_info "Making project public via GitLab API…"
  curl -X PUT \
    -H "PRIVATE-TOKEN: ${PAT}" \
    -H "Content-Type: application/json" \
    -d '{"visibility":"public"}' \
    "http://gitlab.k3d.gitlab.com:8083/api/v4/projects/1"

  log_success "Project set to public"
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

  cd "$SCRIPT_DIR" || log_error "Could not change directory to $SCRIPT_DIR"
  log_info "PRINTING CURRENT DIR----------------: $(pwd)"

  log_info "Applying updated argocd-cm ConfigMap…"
  kubectl apply -f ./confs/argocd-cm.yaml -n argocd
  log_success "Updated argocd-cm applied"

  log_info "Applying ArgoCD Application manifest…"
  kubectl apply -f ./confs/application.yaml -n argocd
  log_success "ArgoCD Application manifest applied"
}

wait_and_portforward_app() {
  log_info "Waiting for service 'wil-playground' in namespace 'dev'…"
  until kubectl get svc wil-playground -n dev &>/dev/null; do
    log_warn "Service not created yet — waiting..."
    sleep 3
  done

  log_info "Starting port-forward to svc/wil-playground → localhost:8888…"
  while true; do
    echo "--- Port-forwarding svc/wil-playground → localhost:8888 ---"
    kubectl port-forward svc/wil-playground -n dev 8888:8888 &
    log_warn "Port-forward died — restarting in 5s"
    sleep 5
  done
}

main() {
  install_docker
  install_git
  install_k3d
  install_kubectl
  create_cluster_and_namespaces
  install_argocd
  install_argocd_client
  deploy_gitlab
  configure_argocd_and_deploy_app
  wait_and_portforward_app
}

main

