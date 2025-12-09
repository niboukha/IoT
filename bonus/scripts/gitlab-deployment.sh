#!/bin/bash
set -eu

echo "=== Starting GitLab deployment script ==="

#install helm
echo "=== Installing Helm ==="
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
echo "=== Helm installed ==="

# cheking and add host
HOST_ENTRY="127.0.0.1 gitlab.k3d.gitlab.com"
HOSTS_FILE="/etc/hosts"

if grep -q "$HOST_ENTRY" "$HOSTS_FILE"; then
    echo "exist $HOSTS_FILE"
else
    echo "adding $HOSTS_FILE"
    echo "$HOST_ENTRY" | sudo tee -a "$HOSTS_FILE"
fi
 
# Install GitLab using Helm in the gitlab namespace
echo "=== Installing GitLab using Helm ==="
sudo helm repo add gitlab https://charts.gitlab.io/
sudo helm repo update 
sudo helm upgrade --install gitlab gitlab/gitlab \
  -n gitlab \
  -f https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml \
  --set global.hosts.domain=gitlab.k3d.gitlab.com \
  --set global.hosts.externalIP=0.0.0.0 \
  --set global.hosts.https=false \
  --set global.gitlabEdition=ce \
  --timeout 600s
echo "=== GitLab installation initiated ==="

echo "=== Waiting for GitLab pods to be ready ==="
sudo kubectl wait --for=condition=ready --timeout=1200s pod -l app=webservice -n gitlab
echo "=== GitLab pods are ready ==="

# Get the initial root password for GitLab
echo "=== Retrieving GitLab initial root password ==="
GITLAB_ROOT_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode)
echo "=== GitLab initial root password retrieved ==="
echo "GitLab Root Password: $GITLAB_ROOT_PASSWORD"

# Port-forward GitLab service to localhost:8081
echo "=== Starting port-forward to svc/gitlab-webservice-default in namespace gitlab on localhost:8081... ==="
kubectl port-forward -n gitlab svc/gitlab-webservice-default 8081:8181 &
echo "=== Port-forward started ==="

echo "=== GitLab deployment script completed ==="



