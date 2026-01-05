#!/usr/bin/env bash
# cleanup-argocd.sh — Uninstall Argo CD and remove most leftovers
set -eu

echo "=== Deleting all Argo CD Applications (optional but recommended) ==="
# You may optionally delete all ArgoCD apps before uninstall — uncomment if desired
# argocd app list -o name | xargs -r -n1 argocd app delete --cascade

echo "=== Deleting Argo CD namespace and core resources ==="
kubectl delete namespace argocd --wait --timeout=180s || echo "namespace argocd already deleted or not present"

echo "=== Deleting Argo CD CustomResourceDefinitions (CRDs) ==="
kubectl get crds | grep -E '(^|\\.)argoproj\\.io$' | awk '{print $1}' | xargs -r kubectl delete crd

echo "=== Deleting leftover ClusterRoles and ClusterRoleBindings of Argo CD ==="
kubectl delete clusterrole,clusterrolebinding -l app.kubernetes.io/part-of=argocd --ignore-not-found

echo "=== Deleting any PersistentVolumeClaims in all namespaces that mention argocd ==="
kubectl get pvc -A | grep -i argocd | awk '{print $1" "$2}' | xargs -r -n2 bash -c 'kubectl delete pvc -n "$0" "$1"' || true

echo "=== Done — Argo CD uninstall cleanup attempted ==="
