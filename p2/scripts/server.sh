echo "Installing K3s server..."

# Ensure net-tools is available so 'ifconfig' can be used in the VM
apt-get update -y
apt-get install -y net-tools

curl -sfL https://get.k3s.io | \
    INSTALL_K3S_EXEC="--node-ip=192.168.56.110 --flannel-iface=eth1" \
    K3S_KUBECONFIG_MODE="644" sh -

sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/k3s_token

# to check kubectl => k
echo "alias k='kubectl'" >> /home/vagrant/.bashrc 

echo "K3s server installed."