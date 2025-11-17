#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JSON_FILE="${1:-"$SCRIPT_DIR/log-files.json"}"

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

if [[ ! -f "$JSON_FILE" ]]; then
  echo "Error: JSON file not found: $JSON_FILE" >&2
  echo "Usage: $0 [path/to/log-files.json]" >&2
  exit 1
fi

OUTPUT_FOLDER="$(jq -r '."output-folder"' "$JSON_FILE")"
mkdir -p "$OUTPUT_FOLDER"

jq -c '.logs[]' "$JSON_FILE" | while IFS= read -r el; do
  download="$(jq -r '.download' <<<"$el")"
  name="$(jq -r '.name' <<<"$el")"
  namespace="$(jq -r '.namespace' <<<"$el")"

  if [[ "$download" != "true" ]]; then
    echo "log files of ${name} is skipped"
    continue
  fi

  mkdir -p "${OUTPUT_FOLDER}/${name}"

  jq -r '.files[]' <<<"$el" | while IFS= read -r filePath; do
    base="$(basename "$filePath")"
    out="${OUTPUT_FOLDER}/${name}/${base}"
    "${SCRIPT_DIR}/kube-download.sh" -n "$namespace" -o "$out" "$name" "$filePath"
  done
done

