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

# If there is file /var/secrets/dkim.pem, copy it to /etc/opendkim/keys/${DKIM_DOMAIN}/${DKIM_SELECTOR}.private and create the directory if it does not exist
# Update file permissions for the private key to be owned by opendkim user and group, and set permissions to 400
if [ -f /var/secrets/dkim.pem ]; then
    mkdir -p /etc/opendkim/keys/${DKIM_DOMAIN}
    cp /var/secrets/dkim.pem /etc/opendkim/keys/${DKIM_DOMAIN}/${DKIM_SELECTOR}.private
    chown opendkim:opendkim /etc/opendkim/keys/${DKIM_DOMAIN}/${DKIM_SELECTOR}.private
    chmod 400 /etc/opendkim/keys/${DKIM_DOMAIN}/${DKIM_SELECTOR}.private
fi

if [ "$DEBUG_MODE" = "true" ]; then
  sed -i '/^command=\/usr\/sbin\/opendkim -f -x \/etc\/opendkim.conf$/s|$| -vvv|' /etc/supervisor/conf.d/supervisord.conf
fi

# Start supervisord
exec /usr/bin/supervisord
