TOKEN=$(cat /vagrant/k3s_token)

curl -sfL https://get.k3s.io | \
  K3S_URL=https://192.168.56.110:6443 \
  K3S_TOKEN=${TOKEN} \
  INSTALL_K3S_EXEC="--node-ip=192.168.56.111 --flannel-iface=eth1" \
  sh -s -
