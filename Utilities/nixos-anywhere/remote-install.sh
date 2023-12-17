#! /run/current-system/sw/bin/bash

ipaddress=$2
hostname=$1

# Install NixOS to the host system with our secrets and encription
nix run github:numtide/nixos-anywhere  -- --flake ../..#$hostname root@$ipaddress
