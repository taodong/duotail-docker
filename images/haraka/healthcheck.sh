#!/bin/bash

# Check if Haraka is running
if pgrep -x "haraka" > /dev/null
then
    exit 0
else
    exit 1
fi