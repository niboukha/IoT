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

log_info "Starting bonus deployment script…"
# cd /vagrant/scripts

install_git() {
  log_info "Installing Git…"
  sudo apt-get -y update
  sudo apt-get install -y git
  log_success "Git installed"
}

install_docker() {
  log_info "Installing Docker…"
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  rm -f get-docker.sh

  # Add the vagrant user to the docker group so vagrant can run Docker commands
  sudo usermod -aG docker vagrant

  log_success "Docker installed"
}

main() {
  install_git
  install_docker
#   cd /vagrant/scripts
#   ./deploy_cluster
#   ./deploy_gitlab
#   echo "alias k='kubectl'" >> /home/vagrant/.bashrc 
  log_success "installation completed"
}

main


