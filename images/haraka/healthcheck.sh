#!/bin/bash

# Check if Haraka is running
if pgrep -f "haraka -c /haraka-duotail" > /dev/null
then
    echo "0" > /var/log/haraka/health_status
    exit 0
else
    echo "1" > /var/log/haraka/health_status
    exit 1
fi