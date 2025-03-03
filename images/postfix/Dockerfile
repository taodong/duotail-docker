FROM ubuntu:latest

ARG SMTP_DOMAIN=example.com
ARG SMTP_PORT=25

RUN apt-get update && \
    apt-get install -y mailutils && \
    apt install -y postfix

COPY config/main.cf.partial /etc/postfix/main.cf

RUN sh -c 'echo "mydomain = ${SMTP_DOMAIN}" >> /etc/postfix/main.cf'

#RUN sh -c 'echo "root: ${EMAIL}" >> /etc/aliases' && \
#    sh -c 'echo "${MAIL_NAME}" >> /etc/mailname' && \
#    sh -c 'echo "[${SMTP_DOMAIN}]:${SMTP_PORT} ${EMAIL}:${EMAIL_PASSWORD}" >> /etc/postfix/sasl_passwd' && \
#    postmap /etc/postfix/sasl_passwd && \
#    chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
#
#CMD service postfix restart && tail -f /dev/null

# Install supervisord
RUN apt-get update && apt-get install -y supervisor

EXPOSE ${SMTP_PORT}
EXPOSE 8080

CMD ["/usr/bin/supervisord"]