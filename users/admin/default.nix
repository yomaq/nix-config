{
  config,
  lib,
  pkgs,
  ...
}:
let
  USER = "admin";
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
      ];
      nixos = with pkgs; [
      ];
    };
    homebrew = { };
  };
  home-manager.users."${USER}" = lib.mkIf (lib.elem USER config.yomaq.users.enableUsers) {
    yomaq = {
      suites.basic.enable = true;
    };
    programs = {
      git = {
        enable = true;
        userEmail = "yomaq@bsjm.xyz";
        userName = "yomaq";
      };
    };
  };
}
