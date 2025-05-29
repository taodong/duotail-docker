#!/bin/bash
set -e

# Create SASL user
echo "$POSTFIX_PASSWORD" | saslpasswd2 -c -p -u "$POSTFIX_DOMAIN" "$POSTFIX_USERNAME"
chown root:sasl /etc/sasldb2
chmod 640 /etc/sasldb2

usermod -a -G sasl postfix

# Start supervisord
exec /usr/bin/supervisord