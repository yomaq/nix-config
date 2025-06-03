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


# the initrd keys don't actually seem to work, but initrd secrets does need some kind of key, or it fails.
# initrd ssh won't work, you will need to manually unlock encryption, then generate new keys.
op read op:"//nix/initrd/private key?ssh-format=openssh" > "$temp/etc/ssh/initrd"
# op read op:"//nix/$hostname-initrd/public key" > "$temp/etc/ssh/$hostname-initrd.pub"

# Set the correct permissions so sshd will accept the key
chmod 600 "$temp/etc/ssh/$hostname"
chmod 600 "$temp/etc/ssh/initrd"

# Install NixOS to the host system with our secrets and encription
nix run github:nix-community/nixos-anywhere -- --extra-files "$temp" --build-on remote \
  --generate-hardware-config nixos-generate-config "$(git rev-parse --show-toplevel)/hosts/$hostname/hardware-configuration.nix" \
  --disk-encryption-keys /tmp/secret.key <(op read op://nix/$hostname/encryption) --flake .#$hostname root@$ipaddress
