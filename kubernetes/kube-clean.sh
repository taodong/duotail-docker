#!/bin/bash

# List all Helm releases and find then remove those with FAILED status
helm list -A --output json | \
  jq -r '.[] | select(.status=="failed") | "\(.name) \(.namespace)"' | \
  while read -r name namespace; do
    echo "Uninstalling failed release: $name in namespace: $namespace"
    helm uninstall "$name" -n "$namespace"
  done

# Remove deployments that have pods stuck in ImagePullBackOff.
# For each pod with ImagePullBackOff, find the owning Deployment (pod -> ReplicaSet -> Deployment).
kubectl get pods -A -o json | jq -c '.items[]' | while read -r pod; do
  ns=$(echo "$pod" | jq -r '.metadata.namespace')
  podname=$(echo "$pod" | jq -r '.metadata.name')

  # check if any container is in ImagePullBackOff
  if echo "$pod" | jq -e '(.status.containerStatuses[]?.state.waiting?.reason) | select(.=="ImagePullBackOff")' >/dev/null 2>&1; then
    echo "Pod $podname in namespace $ns is in ImagePullBackOff"

    owner_kind=$(echo "$pod" | jq -r '.metadata.ownerReferences[0].kind // empty')
    owner_name=$(echo "$pod" | jq -r '.metadata.ownerReferences[0].name // empty')

    deploy=""
    if [ -n "$owner_name" ]; then
      if [ "$owner_kind" = "ReplicaSet" ]; then
        rs="$owner_name"
        # get replicaset owner (likely a Deployment)
        deploy_owner_kind=$(kubectl get rs "$rs" -n "$ns" -o jsonpath='{.metadata.ownerReferences[0].kind}' 2>/dev/null || true)
        deploy_owner_name=$(kubectl get rs "$rs" -n "$ns" -o jsonpath='{.metadata.ownerReferences[0].name}' 2>/dev/null || true)
        if [ "$deploy_owner_kind" = "Deployment" ] && [ -n "$deploy_owner_name" ]; then
          deploy="$deploy_owner_name"
        else
          # fallback: try to infer deployment name from replicaset name by trimming the suffix
          deploy="${rs%-*}"
        fi
      elif [ "$owner_kind" = "Deployment" ]; then
        deploy="$owner_name"
      fi
    fi

    if [ -n "$deploy" ]; then
      # if deployment has a Helm release label, uninstall via Helm to keep release state consistent
      release=$(kubectl get deployment "$deploy" -n "$ns" -o jsonpath='{.metadata.labels.app\.kubernetes\.io/instance}' 2>/dev/null || true)
      if [ -n "$release" ]; then
        echo "Found deployment $deploy in namespace $ns associated with Helm release $release — uninstalling release"
        helm uninstall "$release" -n "$ns" || {
          echo "helm uninstall failed, falling back to deleting deployment $deploy"
          kubectl delete deployment "$deploy" -n "$ns" --ignore-not-found
        }
      else
        echo "Deleting deployment $deploy in namespace $ns"
        kubectl delete deployment "$deploy" -n "$ns" --ignore-not-found
      fi
    else
      echo "Could not determine owning deployment for pod $podname; deleting pod"
      kubectl delete pod "$podname" -n "$ns" --ignore-not-found
    fi
  fi
done