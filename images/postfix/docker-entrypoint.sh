#!/bin/bash
set -e

# Start rsyslog
# Disable imklog to avoid /proc/kmsg error in containers
sed -i '/^module(load="imklog"/s/^/#/' /etc/rsyslog.conf
echo "Starting rsyslog..."
rsyslogd

# Create SASL user
echo "$POSTFIX_PASSWORD" | saslpasswd2 -c -p -u "$POSTFIX_DOMAIN" "$POSTFIX_USERNAME"
chown root:sasl /etc/sasldb2

mkdir -p /var/spool/postfix/etc/
cp /etc/sasldb2 /var/spool/postfix/etc/
chown postfix:sasl /var/spool/postfix/etc/sasldb2
chmod 660 /var/spool/postfix/etc/sasldb2

# Config opendkim socket for postfix
mkdir -p /var/spool/postfix/opendkim
chown postfix:opendkim /var/spool/postfix/opendkim
chmod 770 /var/spool/postfix/opendkim
usermod -aG opendkim postfix

# Update file permissions for opendkim private keys when existing
if [ -d /etc/opendkim/keys ]; then
    find /etc/opendkim/keys -name '*.private' -exec chown opendkim:opendkim {} + -exec chmod 600 {} +
fi

# Start supervisord
exec /usr/bin/supervisord
