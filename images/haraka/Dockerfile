FROM node:23.8.0

ARG HARAKA_VERSION=3.0.5
ARG LISTEN_PORT=25

# Set environment variable
ENV YES_REALLY_DO_DISCARD=true

# Install Haraka
RUN npm install -g haraka@${HARAKA_VERSION}

RUN haraka -i /haraka-duotail

COPY package.json /haraka-duotail/package.json
COPY config/plugins /haraka-duotail/config/plugins
COPY stmp.ini /haraka-duotail/config/smtp.ini

# Install dependencies
RUN cd /haraka-duotail && npm install

expose ${LISTEN_PORT}

# Configure and RUN Haraka as service
RUN mkdir -p /var/log/haraka
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord"]