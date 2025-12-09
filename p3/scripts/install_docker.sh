#!/usr/bin/env bash
set -eu
source "$(dirname "$0")/colors.sh"

info    "Installing Docker…"
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker "$USER"
success "Docker installed"
