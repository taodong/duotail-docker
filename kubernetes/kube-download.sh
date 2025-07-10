#!/bin/bash

# Usage: ./kube-download.sh <POD_PREFIX> <FILE_PATH> [NAMESPACE]

POD_PREFIX="$1"
FILE_PATH="$2"
NAMESPACE="${3:-default}"

if [[ -z "$POD_PREFIX" || -z "$FILE_PATH" ]]; then
  echo "Usage: $0 <POD_PREFIX> <FILE_PATH> [NAMESPACE]"
  exit 1
fi

FILENAME=$(basename "$FILE_PATH")

# Get pods matching the prefix
PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name" | grep "^$POD_PREFIX")

for POD in $PODS; do
  B64FILE="${POD}-${FILENAME}.b64"
  OUTFILE="${POD}-${FILENAME}"

  echo "Copying $FILE_PATH from pod $POD..."
  gtimeout 300 kubectl exec -n "$NAMESPACE" "$POD" -- cat "$FILE_PATH" | base64 > "$B64FILE"

  if [[ $? -eq 124 ]]; then
    echo "Timeout occurred while copying from pod $POD. Skipping."
    rm -f "$B64FILE"
    continue
  fi

  echo "Decoding $B64FILE to $OUTFILE..."
  base64 --decode -i "$B64FILE" -o "$OUTFILE"

  echo "Removing temp file $B64FILE..."
  rm -f "$B64FILE"
done