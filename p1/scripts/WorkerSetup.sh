#!/usr/bin/env bash
set -euo pipefail

echo "=== Updating packages and installing dependencies ==="
sudo apt update -y
sudo apt install -y curl ca-certificates

echo "=== Reading master K3s info ==="
# while [ ! -f /vagrant/node-token ]; do
#   sleep 2
# done
export K3S_URL="https://192.168.56.110:6443"
export K3S_TOKEN="$(cat /vagrant/node-token)"

echo "=== Installing K3s Worker ==="
curl -sfL https://get.k3s.io | \
K3S_URL="$K3S_URL" \
K3S_TOKEN="$K3S_TOKEN" \
INSTALL_K3S_EXEC="agent --node-ip 192.168.56.111" sh -

echo "Worker setup completed!"
