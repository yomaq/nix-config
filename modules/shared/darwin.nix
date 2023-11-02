{ config, lib, pkgs, modulesPath, inputs, ... }:
{
  imports =
    [
      ./options/darwin.nix
      ./common/darwin.nix
    ];
}