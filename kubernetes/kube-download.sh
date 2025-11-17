#!/bin/bash

# Usage: ./kube-download.sh [-n namespace] [-o output_file] <POD_PREFIX> <FILE_PATH>

NAMESPACE="default"
OUTPUT_FILE=""
while getopts ":n:o:" opt; do
  case "$opt" in
    n) NAMESPACE="$OPTARG" ;;
    o) OUTPUT_FILE="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

POD_PREFIX="$1"
FILE_PATH="$2"

if [[ -z "$POD_PREFIX" || -z "$FILE_PATH" ]]; then
  echo "Usage: $0 [-n namespace] [-o output_file] <POD_PREFIX> <FILE_PATH>"
  exit 1
fi

FILENAME=$(basename "$FILE_PATH")

# Get pods matching the prefix
PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name" | grep "^$POD_PREFIX")

for POD in $PODS; do
  # File existence check inside pod
  if ! kubectl exec -n "$NAMESPACE" "$POD" -- test -f "$FILE_PATH"; then
    echo "Error: File '$FILE_PATH' not found in pod '$POD'. Skipping."
    continue
  fi

  # Output file naming logic
  if [[ -n "$OUTPUT_FILE" ]]; then
    DIRNAME=$(dirname "$OUTPUT_FILE")
    BASE=$(basename "$OUTPUT_FILE")
    OUTFILE="${DIRNAME}/${POD}-${BASE}"
  else
    OUTFILE="${POD}-${FILENAME}"
  fi

  B64FILE="${OUTFILE}.b64"

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