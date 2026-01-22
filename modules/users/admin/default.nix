{
  config,
  lib,
  pkgs,
  ...
}:
let
  USER = "admin";
  listOfUsers = config.inventory.hosts."${config.networking.hostName}".users.enableUsers;
in
{
  yomaq.users.users."${USER}" = {
    isRoot = true;
    hasNixosPassword = false;
    authSshKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHYSJ9ywFRJ747tkhvYWFkx/Y9SkLqv3rb7T1UuXVBWo"
    ];
    nixpkgs = {
      common = with pkgs; [
        vim
        gh
        agenix
        just
        nixd
      ];
      nixos = with pkgs; [
      ];
    };
    homebrew = { };
  };
  home-manager.users."${USER}" = lib.mkIf (lib.elem USER listOfUsers) {
    yomaq = {
      suites.basic.enable = true;
    };
    programs = {
      git = {
        enable = true;
        settings = {
          user = {
            email = "yomaq@bsjm.xyz";
            name = "yomaq";
          };
        };
      };
    };
  };
}
