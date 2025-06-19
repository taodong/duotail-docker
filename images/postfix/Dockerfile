FROM ubuntu:25.10

ARG SMTP_DOMAIN=example.com
ARG SMTP_PORT=25

# Install Postfix
RUN apt-get update && \
    apt-get install -y mailutils && \
    apt-get install -y postfix

COPY config/main.cf.partial /etc/postfix/main.cf
COPY config/mailname /etc/mailname

# Add test aliases
RUN echo "mydomain = ${SMTP_DOMAIN}" >> /etc/postfix/main.cf && \
    echo "test: root" >> /etc/aliases && \
    newaliases

RUN echo "test@exmaple.com test@example.com" >> /etc/postfix/virtual && \
    postmap /etc/postfix/virtual

# Install cyrus-sasl2 for SMTP authentication
RUN apt-get update && \
    apt-get install -y sasl2-bin libsasl2-modules

RUN mkdir -p /etc/postfix/sasl
COPY config/smtpd.conf /etc/postfix/sasl/smtpd.conf

# Enable StartTLS
COPY config/master.cf /etc/postfix/master.cf

# Install OpenDKIM
RUN apt-get update && \
    apt-get install -y opendkim opendkim-tools

RUN mkdir -p /etc/opendkim/keys

# Install supervisord
RUN apt-get update && apt-get install -y supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Clean up apt cache
RUN rm -rf /var/lib/apt/lists/*

EXPOSE ${SMTP_PORT}
EXPOSE 587
EXPOSE 8080

# Add health check endpoint
RUN apt-get update && apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -

RUN apt-get install -y nodejs

COPY health_server.js /health_server.js
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Update the entrypoint to use supervisord
COPY docker-entrypoint.sh /usr/bin/docker-entrypoint.sh
RUN chmod +x /usr/bin/docker-entrypoint.sh

CMD ["/usr/bin/docker-entrypoint.sh"]