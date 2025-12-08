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

echo "=== Cleaning up Docker volumes and networks potentially left behind by k3d ==="
# Remove dangling Docker volumes (optional — ensure they are not used by other containers)
docker volume prune -f
# Remove unused Docker networks
docker network prune -f

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
