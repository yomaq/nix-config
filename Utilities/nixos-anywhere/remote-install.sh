#! /run/current-system/sw/bin/bash

echo "ipaddress"
read ipaddress
echo "hostname in flake"
read flake

# Create a temporary directory
temp=$(mktemp -d)

# Function to cleanup temporary directory on exit
cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

# Create the directory where sshd expects to find the host keys
install -d -m755 "$temp/etc/ssh"

# Decrypt your private key for agenix from the password store and copy it to the temporary directory
op read op://chezmoi/agenix-key/agenix > "$temp/etc/ssh/agenix"

# Set the correct permissions so sshd will accept the key
chmod 600 "$temp/etc/ssh/agenix"

# Install NixOS to the host system with our secrets and encription
nix run github:numtide/nixos-anywhere -- --extra-files "$temp" \
  --disk-encryption-keys /tmp/disk-1.key <(op read op://Private/zfs-encription/password) --flake ..#$flake root@$ipaddress