#!/bin/bash

# List all Helm releases and find then remove those with FAILED status or PENDING statuses (pending-install, pending-upgrade, etc.)
helm list -A --output json | \
  jq -r '.[] | select(.status=="failed" or (.status | test("^pending"))) | "\(.name) \(.namespace) \(.status)"' | \
  while read -r name namespace status; do
    echo "Uninstalling release: $name in namespace: $namespace with status: $status"
    helm uninstall "$name" -n "$namespace" || {
      echo "helm uninstall failed for $name in $namespace"
    }
  done

# Remove deployments that have pods stuck in ImagePullBackOff.
# Also remove pods that are Pending for longer than PENDING_AGE_SECS (default 300s).
PENDING_AGE_SECS=${PENDING_AGE_SECS:-600}

kubectl get pods -A -o json | jq -c '.items[]' | while read -r pod; do
  ns=$(echo "$pod" | jq -r '.metadata.namespace')
  podname=$(echo "$pod" | jq -r '.metadata.name')

  # check for pods pending for too long
  phase=$(echo "$pod" | jq -r '.status.phase // empty')
  creation_ts=$(echo "$pod" | jq -r '.metadata.creationTimestamp // empty')

  pending_old=false
  if [ "$phase" = "Pending" ] && [ -n "$creation_ts" ] && [ "$creation_ts" != "null" ]; then
    # compute age in seconds (requires GNU date). Allow override via env PENDING_AGE_SECS.
    if creation_epoch=$(date -d "$creation_ts" +%s 2>/dev/null); then
      now_epoch=$(date +%s)
      age=$((now_epoch - creation_epoch))
      if [ "$age" -ge "$PENDING_AGE_SECS" ]; then
        pending_old=true
      fi
    fi
  fi

  # check if any container is in ImagePullBackOff
  image_pull_backoff=false
  if echo "$pod" | jq -e '(.status.containerStatuses[]?.state.waiting?.reason) | select(.=="ImagePullBackOff")' >/dev/null 2>&1; then
    image_pull_backoff=true
  fi

  if [ "$image_pull_backoff" = "true" ] || [ "$pending_old" = "true" ]; then
    if [ "$pending_old" = "true" ]; then
      echo "Pod $podname in namespace $ns is in Pending for >= ${PENDING_AGE_SECS}s (phase: $phase)"
    else
      echo "Pod $podname in namespace $ns is in ImagePullBackOff"
    fi

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
          kubectl delete deploymentcd "$deploy" -n "$ns" --ignore-not-found
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