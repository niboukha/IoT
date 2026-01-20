#!/usr/bin/env bash
set -euo pipefail

apt update -y
apt install -y curl ca-certificates

curl -sfL https://get.k3s.io | \
INSTALL_K3S_EXEC="server \
  --node-ip 192.168.56.110 \
  --write-kubeconfig-mode 0644" sh -

sleep 10

kubectl apply -f /vagrant/confs

echo "alias k='kubectl'" >> /home/vagrant/.bashrc



# sudo systemctl status k3s --no-pager
# kubectl get all
# kubectl get nodes
# kubectl get deployments
# kubectl get pods
# kubectl get services
# kubectl get ingress
# kubectl get svc

# curl -H "Host: app1.com" http://192.168.56.110
# curl -H "Host: app2.com" http://192.168.56.110
# curl http://192.168.56.110
