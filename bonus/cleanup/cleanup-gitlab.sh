#!/usr/bin/env bash
set -eu

RELEASE="gitlab"
NAMESPACE="${1:-default}"
DELETE_PVS=false

# If first or second argument equals "--delete-pvs", enable PV deletion
if [[ "${1:-}" == "--delete-pvs" ]] || [[ "${2:-}" == "--delete-pvs" ]]; then
  DELETE_PVS=true
fi

echo "🧼 Uninstall Helm release \"$RELEASE\" (namespace: $NAMESPACE)"
helm uninstall "$RELEASE" -n "$NAMESPACE" --ignore-not-found || true

echo "🔎 Delete Helm release secrets (if any)"
kubectl get secrets -n "$NAMESPACE" 2>/dev/null \
  | grep -E "sh.helm.release.v1.${RELEASE}\.v[0-9]+\." \
  | awk '{print $1}' \
  | xargs -r -n1 kubectl delete secret -n "$NAMESPACE"

echo "🧹 Delete Kubernetes resources labeled with release=${RELEASE}"
kubectl delete deployment,sts,svc,svcaccount,roles,rolebindings,configmap,secret,ingress,service,job,cronjob \
  -l release="$RELEASE" -n "$NAMESPACE" --ignore-not-found || true

echo "💾 Delete PVCs (persistent volume claims)"
kubectl delete pvc -l release="$RELEASE" -n "$NAMESPACE" --ignore-not-found || true

if [ "$DELETE_PVS" = true ]; then
  echo "⚠️ Deleting all PVs in the cluster (dangerous — will remove *all* volumes!)"
  kubectl delete pv --all --ignore-not-found || true
fi

echo "🧾 Attempt to delete CRDs that may belong to GitLab or its sub-charts"
kubectl get crds -o name 2>/dev/null \
  | grep -E 'gitlab|gitaly|postgresql|redis|registry|ssl|certmanager|letsencrypt' \
  | xargs -r -n1 kubectl delete crd || true

echo "🧑‍💼 Attempt to delete ClusterRoles / ClusterRoleBindings for GitLab"
kubectl get clusterrole,clusterrolebinding -o name 2>/dev/null \
  | grep -E 'gitlab|gitaly|registry|nginx|ingress|letsencrypt' \
  | xargs -r -n1 kubectl delete || true

read -r -p "Do you want to delete namespace \"$NAMESPACE\" as well? [y/N]: " yn
if [[ "$yn" =~ ^[Yy]$ ]]; then
  kubectl delete namespace "$NAMESPACE" --ignore-not-found
fi


echo "✅ Cleanup script finished. Please double-check cluster for any leftover resources manually if needed."
echo "👉 Example: kubectl get all,crds,clusterrole,clusterrolebinding,pvc,pv --all-namespaces"
