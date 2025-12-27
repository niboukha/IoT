#!/bin/bash
set -eu

GREEN='\033[0;32m'
BOLD='\033[1m'
RESET='\033[0m'

echo "=== Starting GitLab deployment script ==="

echo "=== Installing Helm ==="
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
echo "=== Helm installed ==="

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
  --set global.hosts.domain=k3d.gitlab.com \
  --set global.hosts.externalIP=0.0.0.0 \
  --set global.hosts.https=false \
  --set global.gitlabEdition=ce \
  --timeout 600s
echo "=== GitLab installation initiated ==="

echo "=== Waiting for GitLab pods to be ready ==="
# sudo kubectl wait --for=condition=ready --timeout=1200s pod -l app=webservice -n gitlab
sudo kubectl rollout status deployment gitlab-webservice-default -n gitlab --timeout=300s
echo "=== GitLab pods are ready ==="

GITLAB_PASS=$(sudo kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode)

# Port-forward GitLab service to localhost:8083
echo "=== Starting port-forward to svc/gitlab-webservice-default in namespace gitlab on localhost:8083... ==="
kubectl port-forward -n gitlab svc/gitlab-webservice-default 8083:8181 &
echo "=== Port-forward started ==="

echo "=== GitLab deployment script completed ==="

echo -n "\nGitlab username : root\n"
echo -n "Gitlab password :""${GITLAB_PASS}\n"

echo "=== Configuring Git to connect to GitLab ==="
sudo echo "machine gitlab.k3d.gitlab.com                          
login root
password ${GITLAB_PASS}" > $HOME/.netrc
chmod 600 $HOME/.netrc
echo "=== Git configured ==="

echo "=== init a repo and push to GitLab ==="

cd /Users/nisrinboukhari/Desktop/shichamGitlab

git init
git add .
git commit -m "first commit"
git push --set-upstream http://gitlab.k3d.gitlab.com:8083/root/shicham.git master

echo "=== GitLab repo initialized and pushed ==="

echo "---------------------------------------------====================------------------------------"


echo "=== Generating GitLab Personal Access Token ==="

# Wait for toolbox pod
TOOLBOX_POD=""
while [ -z "$TOOLBOX_POD" ]; do
  TOOLBOX_POD=$(kubectl get pods -n gitlab -l app=toolbox -o jsonpath='{.items[0].metadata.name}')
  echo "Waiting for toolbox pod…" && sleep 5
done
echo "Found toolbox pod: $TOOLBOX_POD"

# Create a token with expiration (365 days from now)
PAT=""

# Generate PAT via Rails runner (must be >= 20 chars)
kubectl exec -n gitlab -it "$TOOLBOX_POD" -- bash -lc "\
gitlab-rails runner ' \
user = User.find_by(username: \"root\"); \
token = user.personal_access_tokens.create!(name: \"cli-token\", scopes: [:api], expires_at: 365.days.from_now.to_date); \
token.set_token(\"mysecuretoken1234567890\"); \
token.save!; \
puts token.token \
' " > /tmp/gitlab_pat.txt

PAT=$(cat /tmp/gitlab_pat.txt | tail -n1 | tr -d '\r\n')

echo "=== PAT created: $PAT"

echo "=== Making project public using API ==="

curl -X PUT \
  -H "PRIVATE-TOKEN: ${PAT}" \
  -H "Content-Type: application/json" \
  -d '{"visibility":"public"}' \
  "http://gitlab.k3d.gitlab.com:8083/api/v4/projects/1"


echo "=== Project should now be public ==="
echo "---------------------------------------------====================------------------------------"