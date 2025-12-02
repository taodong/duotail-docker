#!/bin/bash
#
# Check the environment for certificate auto renewal
#

# -----------------------------
# Required variables (from environment)
# -----------------------------
: "${DOMAIN:?Error: DOMAIN environment variable is required}"
: "${NB_ID:?Error: NB_ID environment variable is required}"
: "${CONFIG_ID:?Error: CONFIG_ID environment variable is required}"

CERT_PATH="/root/.acme.sh/${DOMAIN}_ecc/${DOMAIN}.cer"
CHAIN_PATH="/root/.acme.sh/${DOMAIN}_ecc/fullchain.cer"
KEY_PATH="/root/.acme.sh/${DOMAIN}_ecc/${DOMAIN}.key"

# Verify certificate files exist
if [ ! -f "$CERT_PATH" ]; then
  echo "Error: certificate not found at $CERT_PATH"
  exit 1
fi
if [ ! -f "$CHAIN_PATH" ]; then
  echo "Error: chain certificate not found at $CHAIN_PATH"
  exit 1
fi
if [ ! -f "$KEY_PATH" ]; then
  echo "Error: private key not found at $KEY_PATH"
  exit 1
fi

echo "Environment check passed: all required variables and files are present."