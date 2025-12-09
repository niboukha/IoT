#!/usr/bin/env bash
set -eu

BASEDIR=$(dirname "$0")

chmod +x "${BASEDIR}/"*.sh

for script in \
  install_k3d.sh \
  create_cluster_and_namespaces.sh \
  install_argocd.sh \
  configure_argocd_and_deploy_app.sh \
  wait_and_portforward.sh
do
  "${BASEDIR}/${script}"
done

echo
echo "✅ All steps completed."
echo "You can now access the ArgoCD UI at http://localhost:8080"