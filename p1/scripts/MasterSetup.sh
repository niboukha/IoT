#!/usr/bin/env bash
set -euo pipefail

echo "=== Updating packages and installing dependencies ==="
sudo apt update -y
sudo apt install -y curl ca-certificates

echo "=== Installing K3s Master ==="
# Disable Traefik & metrics-server to reduce RAM usage
curl -sfL https://get.k3s.io | \
INSTALL_K3S_EXEC="server \
  --node-ip 192.168.56.110 \
  --write-kubeconfig-mode 0644 \
  --disable=traefik \
  --disable=metrics-server" sh -

echo "=== Checking K3s status ==="
sudo systemctl status k3s --no-pager

echo "=== Waiting a few seconds for K3s to be ready ==="
sleep 5

echo "=== Display nodes ==="
kubectl get nodes

echo "=== Copy node token to shared folder ==="
sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token

echo "Master setup completed!"
