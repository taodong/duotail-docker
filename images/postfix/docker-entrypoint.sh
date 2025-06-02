#!/bin/bash
set -e

# Create SASL user
echo "$POSTFIX_PASSWORD" | saslpasswd2 -c -p -u "$POSTFIX_DOMAIN" "$POSTFIX_USERNAME"
chown root:sasl /etc/sasldb2

mkdir -p /var/spool/postfix/etc/
cp /etc/sasldb2 /var/spool/postfix/etc/
chown postfix:sasl /var/spool/postfix/etc/sasldb2
chmod 660 /var/spool/postfix/etc/sasldb2

# Start supervisord
exec /usr/bin/supervisord
