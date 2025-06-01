#!/bin/bash
set -e

# Create a system user for SMTP authentication (via saslauthd using PAM)
if id "${POSTFIX_USERNAME}" &>/dev/null; then
  echo "User ${POSTFIX_USERNAME} already exists"
else
  useradd -m -s /usr/sbin/nologin "${POSTFIX_USERNAME}"
  echo "${POSTFIX_USERNAME}:${POSTFIX_PASSWORD}" | chpasswd
  echo "Created user ${POSTFIX_USERNAME}"
fi

# Start supervisord
exec /usr/bin/supervisord