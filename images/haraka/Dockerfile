FROM node:23.8.0

ARG HARAKA_VERSION=3.0.5
ARG LISTEN_PORT=25

# Set environment variable
ENV YES_REALLY_DO_DISCARD=true

# Install Haraka
RUN npm install -g Haraka@${HARAKA_VERSION}

RUN haraka -i /haraka-duotail

COPY package.json /haraka-duotail/package.json
COPY config/plugins /haraka-duotail/config/plugins
COPY config/smtp.ini /haraka-duotail/config/smtp.ini

# Install dependencies
RUN cd /haraka-duotail && npm install

# Copy duotail plugin to plugins directory
RUN cp -r /haraka-duotail/node_modules/@tao.dong/haraka-plugin-duotail /haraka-duotail/plugins/duotail

# Install supervisord
RUN apt-get update && apt-get install -y supervisor

EXPOSE ${LISTEN_PORT}

# Configure and RUN Haraka as service
RUN mkdir -p /var/log/haraka
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD /healthcheck.sh || exit 1

CMD ["/usr/bin/supervisord"]