#! /run/current-system/sw/bin/bash

ipaddress=$2
hostname=$1

eval $(op signin)

# Create a temporary directory
temp=$(mktemp -d)

# Function to cleanup temporary directory on exit
cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

# Create the directory where sshd expects to find the host keys
install -d -m755 "$temp/etc/ssh/"

# Obtain your private key for agenix from the password store and copy it to the temporary directory
# also copy the key for the initrd shh server
op read op:"//nix/$hostname/private key?ssh-format=openssh" > "$temp/etc/ssh/$hostname"
op read op:"//nix/$hostname-initrd/private key?ssh-format=openssh" > "$temp/etc/ssh/$hostnameInitrd.key"
op read op:"//nix/$hostname-initrd/public key" > "$temp/etc/ssh/$hostnameInitrd.pub"

# Set the correct permissions so sshd will accept the key
chmod 600 "$temp/etc/ssh/$hostname"
chmod 600 "$temp/etc/ssh/$hostnameInitrd.key"

# Install NixOS to the host system with our secrets and encription
nix run github:numtide/nixos-anywhere -- --extra-files "$temp"  \
  --disk-encryption-keys /tmp/secret.key <(op read op://nix/$hostname/encryption) --flake ..#$hostname root@$ipaddress