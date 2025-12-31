#!/usr/bin/env bash
# cleanup-k3d.sh — Delete all k3d clusters + optional uninstall of k3d

set -eu

echo "=== Deleting all k3d clusters ==="
if k3d cluster list | grep -q "."; then
  # Delete all clusters
  k3d cluster delete --all
  echo "All k3d clusters deleted."
else
  echo "No k3d clusters found."
fi

# docker stop $(docker ps -aq)
# docker rm $(docker ps -aq)
# docker rmi -f $(docker images -aq)
# docker volume rm $(docker volume ls -q)
# docker network rm $(docker network ls -q)
# echo "All Docker containers, images, volumes, and networks removed.

# Ask user whether to uninstall k3d CLI (remove binary)
read -p "Do you want to uninstall k3d CLI binary from system? (y/N) " UNINSTALL_CLI
if [ "$UNINSTALL_CLI" = "y" ] || [ "$UNINSTALL_CLI" = "Y" ]; then
  K3D_BIN=$(which k3d || true)
  if [[ -n "$K3D_BIN" ]]; then
    echo "Removing k3d binary at $K3D_BIN"
    sudo rm -f "$K3D_BIN"
    echo "k3d CLI removed."
  else
    echo "k3d binary not found — perhaps already removed."
  fi
fi

echo "=== Done ==="

echo "Stopping Docker services..."
sudo systemctl stop docker.service docker.socket 2>/dev/null || true

echo "Removing Docker packages..."
sudo apt-get purge -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    docker.io

echo "Removing leftover dependencies..."
sudo apt-get autoremove -y

echo "Removing Docker data and config..."
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm -rf /etc/docker

echo "Removing Docker repository lists and keyrings..."
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/sources.list.d/docker.sources
sudo rm -f /etc/apt/keyrings/docker*.gpg

echo "Removing docker group..."
sudo groupdel docker 2>/dev/null || true

echo "Docker uninstall completed."
