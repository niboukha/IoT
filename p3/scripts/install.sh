#!/usr/bin/env bash

set -eu

# Install k3d (Kubernetes in Docker) CLI
echo "=== Installing k3d ==="
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
echo "=== k3d installed ==="

# Create a k3d cluster
echo "=== Creating k3d cluster ==="
k3d cluster create p3
echo "=== k3d cluster created ==="

# Create namespaces for ArgoCD and the application
echo "=== Creating namespaces ==="
kubectl create namespace argocd
kubectl create namespace dev
echo "=== K3d cluster and namespaces created ==="

# Install ArgoCD into the argocd namespace
echo "=== Installing ArgoCD into namespace argocd ==="
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "=== Wait until ArgoCD server deployment is ready ==="
kubectl -n argocd rollout status deployment/argocd-server --timeout=120s

#install argocd
echo "=== Installing ArgoCD ==="
curl -sSL -o /tmp/argocd-install.yaml https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f /tmp/argocd-install.yaml
echo "=== ArgoCD installed ==="

# # Install ArgoCD CLI
# echo "=== Installing ArgoCD CLI ==="
# sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
# sudo chmod +x /usr/local/bin/argocd
# echo "=== ArgoCD CLI installed ==="

# Login to ArgoCD server
echo "=== Logging into ArgoCD server ==="
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
sleep 5  # Wait for port-forward to establish
argocd login localhost:8080 --insecure --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "=== Logged into ArgoCD server ==="

# Change ArgoCD admin password
echo "=== Changing ArgoCD admin password ==="
argocd account update-password --current-password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d) --new-password "incept123!"
echo "=== ArgoCD admin password changed ==="

# Apply updated argocd-cm
echo "=== Applying updated argocd-cm ConfigMap ==="
kubectl apply -f ../confs/argocd-cm.yaml -n argocd
echo "=== Updated argocd-cm ConfigMap applied ==="

#apply application manifest
echo "=== Applying ArgoCD Application manifest ==="
kubectl apply -f ../confs/application.yaml -n argocd
echo "=== ArgoCD Application manifest applied ==="

# Wait for the wil-playground service and pod to be ready
echo "=== Waiting for service to exist... ==="
until kubectl get svc wil-playground -n dev 2>/dev/null; do
  echo "Service not created yet — waiting..."
  sleep 3
done

echo "=== Waiting for at least one pod to be ready... ==="
kubectl wait pod -n dev -l app=wil-playground --for condition=Ready --timeout=60s

# Port-forward the wil-playground service to localhost:8888
echo "=== Starting port-forward to svc/wil-playground in namespace dev on localhost:8888... ==="
while true; do
  echo "--- Trying to port‑forward svc/wil-playground in namespace dev... ---"
  kubectl port-forward svc/wil-playground -n dev 8888:8888 &
  echo "--- Port-forward died — restarting in 5s ---"
  sleep 5
done

echo "=== Setup complete ==="
