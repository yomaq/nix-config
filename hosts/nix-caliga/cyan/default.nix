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
    ./microvm.nix
    ./stubs.nix
  ];

  layeredImage = {
    name = "ghcr.io/yomaq/nix-config";
    tag = "cyan";
    maxLayers = 135;
    fromImage = pkgs.dockerTools.pullImage {
      imageName = "ghcr.io/projectbluefin/dakota";
      imageDigest = "sha256:06f5511bca3ce5b44cb9069c2f34d77823b300ae7aada9e177075e986103b28e";
      hash = "sha256-GLNl3QUQcjBix5IGyYAUZRWPWU9fg06vya/JxjBOZKk=";
      finalImageName = "ghcr.io/projectbluefin/dakota";
      finalImageTag = "latest";
    };
  };

  caliga.os = "gnomeOS";
  caliga.core.enable = true;

  inventory.hosts.cyan.users.enableUsers = [ "carln" ];

  users.users.carln.shell = lib.mkForce "/usr/bin/bash";

  age.identityPaths = [ "/etc/ssh/cyan" ];

  system.stateVersion = "25.11";
}
