{ config, lib, pkgs, modulesPath, inputs, ... }:
{
  imports =
    [
      ./options/nixos.nix
      ./common/nixos.nix
    ];
}