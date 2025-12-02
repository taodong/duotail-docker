# Certs Node Utility Scripts

This directory contains utility scripts for managing certificates on a node.

All scripts in this directory should be uploaded to the target node's /opt/bin directory.

## Scripts
- `env-check.sh`: A script to check required environment for certificate auto renewal.
- `certs-renew.sh`: A script to upload certs into targeted load balancer.
- `renewal-cron.sh`: A script to set up a cron job for automatic certificate renewal. It accepts an optional argument `-d` to delete the existing cron job.