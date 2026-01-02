#!/usr/bin/env bash
set -euo pipefail

# Color definitions
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m"

echo "=== Starting k3d cluster deployment script ==="
log_info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
log_success() { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1" >&2; }

install_docker() {
  log_info "Installing Docker…"
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  # sudo usermod -aG docker "$USER"
  sudo chmod 666 /var/run/docker.sock
#   su - "$USER" << EOF
#   newgrp docker << EOF
# echo "Group membership refreshed"
# EOF
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
  # kubectl -n argocd rollout status deployment/argocd-server --timeout=120s
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

  # Install Helm if not already installed
  log_info "Installing Helm…"
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  log_success "Helm installed"

  # Add hosts entry for local DNS resolution
  HOST_ENTRY="127.0.0.1 gitlab.k3d.gitlab.com"
  HOSTS_FILE="/etc/hosts"
  if grep -q "$HOST_ENTRY" "$HOSTS_FILE"; then
    log_info "Hosts entry already exists"
  else
    log_info "Adding hosts entry for GitLab"
    echo "$HOST_ENTRY" | sudo tee -a "$HOSTS_FILE" >/dev/null
  fi

  # Add and update Helm repo
  helm repo add gitlab https://charts.gitlab.io/
  helm repo update

  # Install GitLab with Helm chart (using minimal example values)
  log_info "Installing GitLab chart…"
  log_info "Installing GitLab chart…"
  helm upgrade --install gitlab gitlab/gitlab \
    -n gitlab \
    -f https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml \
    -f $HOME/Desktop/Inception-of-Things-IoT-/bonus/confs/gitlab-values.yaml \
    --set global.hosts.domain=k3d.gitlab.com \
    --set global.hosts.externalIP=0.0.0.0 \
    --set global.hosts.https=false \
    --set global.gitlabEdition=ce \
    --timeout 600s
  log_success "GitLab chart installed"

  # Configure kubectl to use the new cluster
  # log_info "Configuring kubectl to use the new cluster…"
  # mkdir -p /home/vagrant/.kube
  # sudo cp -i /root/.kube/config /home/vagrant/.kube/config
  # sudo chown vagrant:vagrant /home/vagrant/.kube/config
  # log_success "kubectl configured"

  # log_info "Waiting for GitLab webservice to be ready…"
  # kubectl rollout status deployment gitlab-webservice-default -n gitlab --timeout=300s

  log_info "Waiting for GitLab webservice to be ready…"

  until kubectl get pods -n gitlab -l app=webservice \
    -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' \
    | grep -q True; do
      echo "Still waiting for GitLab webservice..."
      sleep 20
  done

  log_info "GitLab webservice is ready ✅"


  # Get initial root password
  GITLAB_PASS=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode)
  log_success "GitLab installed and ready"

  # Port‑forward GitLab UI
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

  # Configure Git for pushing
  log_info "Configuring Git to talk to GitLab…"
  cat <<EOF > "$HOME/.netrc"
machine gitlab.k3d.gitlab.com
login root
password $GITLAB_PASS
EOF
  chmod 600 "$HOME/.netrc"
  log_success "Git configured"

  # Initialize and push to GitLab (modify path & repo info as needed)
  log_info "Initializing local Git repo and pushing to GitLab…"
  cd "$HOME/Desktop/shichamGitlab" || log_error "Repo directory not found"
  git init
  git add .
  git commit -m "first commit"
  git push --set-upstream "http://gitlab.k3d.gitlab.com:8083/root/shicham.git" master

  # clone from github

  GITHUB_USERNAME="niboukha"
  GITHUB_TOKEN="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"

  # Directory where you want to clone
  CLONE_DIR="/vagrant/shicham"

  # echo "Cloning GitHub repo via HTTPS with token..."
  # git clone "https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/shicham.git" "${CLONE_DIR}"

  # cd shicham || log_error "Cloned repo directory not found"
  # git remote rename origin upstream
  # git remote add origin "http://gitlab.k3d.gitlab.com:8083/root/shicham.git"
  # git push --set-upstream origin --all
  # git push origin --tags

  # log_success "Repo initialized and pushed"

  # Generate GitLab PAT for API use
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

  # Make project public
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
  kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8080:443 &
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
  kubectl apply -f $HOME/Desktop/Inception-of-Things-IoT-/bonus/confs/argocd-cm.yaml -n argocd
  log_success "Updated argocd-cm applied"

  log_info "Applying ArgoCD Application manifest…"
  kubectl apply -f $HOME/Desktop/Inception-of-Things-IoT-/bonus/confs/application.yaml -n argocd
  log_success "ArgoCD Application manifest applied"
}

wait_and_portforward_app() {
  log_info "Waiting for service 'wil-playground' in namespace 'dev'…"
  until kubectl get svc wil-playground -n dev &>/dev/null; do
    log_warn "Service not created yet — waiting..."
    sleep 3
  done

  # log_info "Waiting for at least one pod with label app=wil-playground to be ready…"
  # kubectl rollout status deployment/wil-playground -n dev --timeout=120s
  # log_success "Service and pod are ready"

  log_info "Starting port-forward to svc/wil-playground → localhost:8888…"
  while true; do
    echo "--- Port-forwarding svc/wil-playground → localhost:8888 ---"
    kubectl port-forward --address 0.0.0.0 svc/wil-playground -n dev 8888:8888 &
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

