#!/bin/bash

# This script is the entry point for the git server container. It sets up the necessary environment and starts the git sshd service.

# Do we have an authorized_keys environment variable?
if [ -n "$AUTHORIZED_KEYS" ]; then
    echo "Setting up authorized_keys..."
    mkdir -p /root/.ssh
    mkdir -p /home/git/.ssh
    echo "$AUTHORIZED_KEYS" > /root/.ssh/authorized_keys
    echo "$AUTHORIZED_KEYS" > /home/git/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    chmod 600 /home/git/.ssh/authorized_keys
    chown -R git:git /home/git/.ssh
else
    echo "No AUTHORIZED_KEYS environment variable found. Exiting."
    exit 1
fi

# Create the log directory for cron jobs
mkdir -p /home/git/.logs

# Set the correct permissions for the git user
chown -R git:git /home/git
chown -R git:git /repositories

# Start the cron service
echo "Starting cron service..."
cron

# Generate SSH host keys into the persistent volume if they don't exist yet.
# This keeps keys stable across container rebuilds.
mkdir -p /run/ssh
chmod 700 /run/ssh
if [ ! -f /run/ssh/ssh_host_ed25519_key ]; then
    echo "Generating SSH host keys..."
    ssh-keygen -q -N "" -t rsa -b 4096 -f /run/ssh/ssh_host_rsa_key
    ssh-keygen -q -N "" -t ecdsa -f /run/ssh/ssh_host_ecdsa_key
    ssh-keygen -q -N "" -t ed25519 -f /run/ssh/ssh_host_ed25519_key
fi

# Start the SSH service in the background
echo "Starting SSH service..."
/usr/sbin/sshd -D -E /var/log/sshd.log &

# Wait for the SSH service to start
sleep 2

# Watch the SSH log for any errors
tail -f /var/log/sshd.log