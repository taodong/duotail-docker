FROM node:26.7.0

ARG HARAKA_VERSION=3.3.3
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

# PATCH: haraka-plugin-mailauth 1.1.1 predates Haraka 3.3's address API change.
# Core now passes an @haraka/email-address Address whose `.address` is a getter,
# not a method, so the plugin's `params[0].address()` throws in hook_mail and
# SPF/DKIM never run. Upstream is unmaintained (1.1.1 is latest, ~1yr old).
# The grep guards make the build FAIL LOUDLY if upstream ever changes this line,
# rather than silently producing an image with no DKIM checking.
# See mailauth-patch-instructions.md. Remove if upstream ships a Haraka 3.3 fix.
RUN cd /haraka-duotail/node_modules/haraka-plugin-mailauth && \
    grep -q 'const sender = params\[0\]\.address();' index.js && \
    sed -i 's/const sender = params\[0\]\.address();/const sender = params[0].address;/' index.js && \
    grep -q 'const sender = params\[0\]\.address;' index.js

# Copy duotail plugin to plugins directory
RUN cp -r /haraka-duotail/node_modules/@tao.dong/haraka-plugin-duotail /haraka-duotail/plugins/duotail

# Install supervisord, cron and logrotate
RUN apt-get update && apt-get install -y supervisor cron logrotate

EXPOSE ${LISTEN_PORT}
EXPOSE 8080

# Configure and RUN Haraka as service
RUN mkdir -p /var/log/haraka
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh

# Add health check endpoint
COPY health_server.js /health_server.js

# Add logrotate configuration for haraka logs
COPY logrotate/haraka /etc/logrotate.d/haraka
RUN chmod 644 /etc/logrotate.d/haraka

# Add health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

CMD ["/usr/bin/supervisord"]