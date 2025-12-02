#!/bin/bash
#
# Upload Let’s Encrypt cert + key from acme.sh to a Linode NodeBalancer
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

# -----------------------------
# Build SSL cert (fullchain)
# NodeBalancer requires cert + chain together
# -----------------------------
TMP_CERT="/tmp/${DOMAIN}_nb_fullchain.pem"
cat "$CERT_PATH" "$CHAIN_PATH" > "$TMP_CERT"

# -----------------------------
# Push via linode-cli
# -----------------------------
echo "Uploading certificate for $DOMAIN to NodeBalancer $NB_ID..."

linode-cli nodebalancers config-update \
    "$NB_ID" "$CONFIG_ID" \
    --ssl_cert="$(cat $TMP_CERT)" \
    --ssl_key="$(cat $KEY_PATH)"

STATUS=$?

if [ $STATUS -ne 0 ]; then
    echo "❌ Upload failed!"
    exit 1
fi

echo "✅ NodeBalancer certificate updated successfully."

# Cleanup
rm -f "$TMP_CERT"