{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports =
    [
       ./nix+nixos-config.nix
    ];
}
