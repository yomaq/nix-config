{
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    (inputs.self + /modules/hosts/user/default.nix)
    (inputs.self + /modules/hosts/user/nixos.nix)
    # ./microvm.nix
    ./stubs.nix
  ];

  layeredImage = {
    name = "ghcr.io/yomaq/nix-config";
    tag = "cyan";
    maxLayers = 270;
    fromImage = pkgs.dockerTools.pullImage inputs.bootc-image-prefetcher.pins.fedora-silverblue."44";
  };

  caliga.os = "fedora";
  caliga.core.enable = true;

  inventory.hosts.cyan.users.enableUsers = [ "carln" ];

  users.users.carln.shell = lib.mkForce "/usr/bin/bash";

  age.identityPaths = [ "/etc/ssh/cyan" ];

  system.stateVersion = "25.11";
}
