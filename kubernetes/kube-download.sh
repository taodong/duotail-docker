#!/bin/bash
# Usage: ./kube-download.sh [-n namespace] [-o output_file] [-r retries] [-c container] <POD_PREFIX> <FILE_PATH>
set -euo pipefail

NAMESPACE="default"
OUTPUT_FILE=""
RETRIES=3
CONTAINER=""

while getopts ":n:o:r:c:" opt; do
  case "$opt" in
    n) NAMESPACE="$OPTARG" ;;
    o) OUTPUT_FILE="$OPTARG" ;;
    r) RETRIES="$OPTARG" ;;
    c) CONTAINER="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

POD_PREFIX="${1:-}"
FILE_PATH="${2:-}"

if [[ -z "$POD_PREFIX" || -z "$FILE_PATH" ]]; then
  echo "Usage: $0 [-n namespace] [-o output_file] [-r retries] [-c container] <POD_PREFIX> <FILE_PATH>"
  exit 1
fi

FILENAME=$(basename "$FILE_PATH")
PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name" | grep "^$POD_PREFIX" || true)

if [[ -z "$PODS" ]]; then
  echo "No pods match prefix '$POD_PREFIX' in namespace '$NAMESPACE'"
  exit 1
fi

for POD in $PODS; do
  # Build exec base (adds -c only if provided)
  if [[ -n "$CONTAINER" ]]; then
    KEXEC=(kubectl exec -n "$NAMESPACE" -c "$CONTAINER" "$POD" --)
  else
    KEXEC=(kubectl exec -n "$NAMESPACE" "$POD" --)
  fi

  if ! "${KEXEC[@]}" test -f "$FILE_PATH"; then
    echo "[${POD}] Skipping: file not found"
    continue
  fi

  if [[ -n "$OUTPUT_FILE" ]]; then
    DIRNAME=$(dirname "$OUTPUT_FILE")
    BASE=$(basename "$OUTPUT_FILE")
    OUTFILE="${DIRNAME}/${POD}-${BASE}"
  else
    OUTFILE="${POD}-${FILENAME}"
  fi

  echo "[${POD}] Attempting kubectl cp..."
  CPCMD=(kubectl cp -n "$NAMESPACE")
  [[ -n "$CONTAINER" ]] && CPCMD+=(-c "$CONTAINER")
  CPCMD+=("${POD}:${FILE_PATH}" "$OUTFILE")
  if "${CPCMD[@]}" 2>/dev/null; then
    echo "[${POD}] Success via kubectl cp -> $OUTFILE"
    continue
  else
    echo "[${POD}] kubectl cp failed; fallback to direct stream"
  fi

  REMOTE_SIZE=$("${KEXEC[@]}" sh -c "stat -c %s '$FILE_PATH' 2>/dev/null || wc -c < '$FILE_PATH'" || echo 0)

  attempt=1
  while (( attempt <= RETRIES )); do
    echo "[${POD}] Stream attempt ${attempt}/${RETRIES}..."
    # Direct binary stream (avoids base64 EOF issues)
    if "${KEXEC[@]}" sh -c "cat '$FILE_PATH'" > "${OUTFILE}.part"; then
      LOCAL_SIZE=$(wc -c < "${OUTFILE}.part" || echo 0)
      if [[ "$REMOTE_SIZE" -gt 0 && "$LOCAL_SIZE" -ne "$REMOTE_SIZE" ]]; then
        echo "[${POD}] Size mismatch (remote=${REMOTE_SIZE} local=${LOCAL_SIZE}); retrying"
        rm -f "${OUTFILE}.part"
      else
        mv "${OUTFILE}.part" "$OUTFILE"
        echo "[${POD}] Success via direct stream -> $OUTFILE (size=${LOCAL_SIZE})"
        break
      fi
    else
      echo "[${POD}] Stream failed; retrying"
      rm -f "${OUTFILE}.part" || true
    fi
    (( attempt++ ))
    sleep 2
  done

  if (( attempt > RETRIES )); then
    echo "[${POD}] All fallback attempts failed"
  fi
done
