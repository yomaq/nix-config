{ config, lib, pkgs, modulesPath, inputs, ... }:
{
  imports =
    [
      ./options
      ./common
            (inputs.self + ./modules/shared/nixos.nix)
    ];
}