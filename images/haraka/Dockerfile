FROM node:23.8.0

ARG HARAKA_VERSION=3.0.5
ARG LISTEN_PORT=25

# Set environment variable
ENV YES_REALLY_DO_DISCARD=true

# Remove libwmf and dev package to avoid AGPL-3 license issues
RUN apt-get update && \
    apt-get remove -y libwmf-dev libwmf0.2-7 libwmflite-0.2-7 && \
    apt-get autoremove -y

# Install Haraka
RUN npm install -g Haraka@${HARAKA_VERSION}

RUN haraka -i /haraka-duotail

COPY package.json /haraka-duotail/package.json
COPY config/plugins /haraka-duotail/config/plugins
COPY config/smtp.ini /haraka-duotail/config/smtp.ini
COPY config/host_list /haraka-duotail/config/host_list


# Install dependencies
RUN cd /haraka-duotail && npm install

# Copy duotail plugin to plugins directory
RUN cp -r /haraka-duotail/node_modules/@tao.dong/haraka-plugin-duotail /haraka-duotail/plugins/duotail

# Install supervisord
RUN apt-get update && apt-get install -y supervisor

EXPOSE ${LISTEN_PORT}
EXPOSE 8080

# Configure and RUN Haraka as service
RUN mkdir -p /var/log/haraka
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh

# Add health check endpoint
COPY health_server.js /health_server.js
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

CMD ["/usr/bin/supervisord"]