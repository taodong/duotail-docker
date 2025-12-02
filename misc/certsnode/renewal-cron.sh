#!/usr/bin/env bash
set -euo pipefail

# Optional delete flag: if "-d" is provided as the first arg, run in delete mode
DELETE_MODE=false
if [[ "${1:-}" == "-d" ]]; then
  DELETE_MODE=true
fi

# Require root since the cron entry targets /root paths
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Error: must be run as root." >&2
  exit 1
fi

DOMAIN="${DOMAIN:-}"
if [[ -z "$DOMAIN" ]]; then
  echo "Error: DOMAIN environment variable is required." >&2
  exit 1
fi

CRON_LINE="0 3 * * * /root/.acme.sh/acme.sh --renew -d ${DOMAIN} && /opt/bin/certs-renew.sh"

# Read existing crontab (may be empty)
EXISTING="$(crontab -l 2>/dev/null || true)"

if [[ "$DELETE_MODE" == true ]]; then
  # Delete mode: remove the exact cron line if present
  if echo "$EXISTING" | grep -Fxq "$CRON_LINE"; then
    NEW_CRON="$(echo "$EXISTING" | grep -Fxv "$CRON_LINE")"
    # Install updated crontab (handles empty output too)
    if [[ -n "$NEW_CRON" ]]; then
      printf "%s\n" "$NEW_CRON" | crontab -
    else
      crontab -r || true
    fi
    echo "Cron job removed."
    exit 0
  else
    echo "Cron job not found; nothing to remove."
    exit 0
  fi
fi

# Idempotency: if the exact line exists, do nothing
if echo "$EXISTING" | grep -Fxq "$CRON_LINE"; then
  echo "Cron job already present."
  exit 0
fi

# Append and install
printf "%s\n%s\n" "$EXISTING" "$CRON_LINE" | crontab -
echo "Cron job installed."
