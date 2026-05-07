#!/bin/bash

# This script is the entry point for the git server container. It sets up the necessary environment and starts the git sshd service.

# Do we have an authorized_keys environment variable?
if [ -n "$AUTHORIZED_KEYS" ]; then
    echo "Setting up authorized_keys..."
    mkdir -p /home/git/.ssh
    echo "$AUTHORIZED_KEYS" > /home/git/.ssh/authorized_keys
    chmod 600 /home/git/.ssh/authorized_keys
    chown -R git:git /home/git/.ssh
else
    echo "No AUTHORIZED_KEYS environment variable found. Exiting."
    exit 1
fi

# Set the correct permissions for the git user
chown -R git:git /home/git

# Start the SSH service in the background
echo "Starting SSH service..."
/usr/sbin/sshd -D -E /var/log/sshd.log &

# Wait for the SSH service to start
sleep 2

# Watch the SSH log for any errors
tail -f /var/log/sshd.log