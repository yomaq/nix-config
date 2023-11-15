#! /run/current-system/sw/bin/bash

ipaddress=$1
hostname=$2
persistentDir=$3

# Create a temporary directory
temp=$(mktemp -d)

# Function to cleanup temporary directory on exit
cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

# Create the directory where sshd expects to find the host keys
# install -d -m755 "$temp $persistentDir/etc/ssh/"
install -d -m755 "$temp/etc/ssh/"

# Obtain your private key for agenix from the password store and copy it to the temporary directory
# op read op:"//nix/$hostname/private key" > "$temp $persistentDir/etc/ssh/$hostname"
op read op:"//nix/$hostname/private key" > "$temp/etc/ssh/$hostname"

# Set the correct permissions so sshd will accept the key
chmod 600 "$temp/etc/ssh/$hostname"

# Install NixOS to the host system with our secrets and encription
nix run github:numtide/nixos-anywhere -- --build-on-remote --no-reboot --extra-files "$temp"  \
  --disk-encryption-keys /tmp/secret.key <(op read op://nix/$hostname/encryption) --flake ..#$hostname root@$ipaddress