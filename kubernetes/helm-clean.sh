#!/bin/bash

# List all Helm releases and find then remove those with FAILED status
helm list -A --output json | \
  jq -r '.[] | select(.status=="failed") | "\(.name) \(.namespace)"' | \
  while read -r name namespace; do
    echo "Uninstalling failed release: $name in namespace: $namespace"
    helm uninstall "$name" -n "$namespace"
  done