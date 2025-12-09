#!/usr/bin/env bash
set -eu
source "$(dirname "$0")/colors.sh"

info    "Installing k3d (Kubernetes in Docker CLI)…"
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
success "k3d installed"
