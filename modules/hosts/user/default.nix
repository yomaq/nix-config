{
  config,
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  options.yomaq.users = {
    enableUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of users to enable on a host. Users must be defined eslewhere.";
    };
    users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            isRoot = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Root Permissions";
            };
            hasNixosPassword = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "passwordless by default";
            };
            authSshKeys = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "authorized ssh key";
            };
            homebrew = lib.mkOption {
              type = lib.types.attrs;
              default = { };
              description = "Nix-Darwin Homebrew Options";
            };
            nixpkgs = {
              common = lib.mkOption {
                type = lib.types.listOf lib.types.package;
                default = [ ];
                description = "List of packages to install for both NixOS and Darwin";
                example = "with pkgs; [ git vim ]";
              };
              nixos = lib.mkOption {
                type = lib.types.listOf lib.types.package;
                default = [ ];
                description = "List of packages to install for NixOS only";
                example = "with pkgs; [ firefox steam ]";
              };
            };
          };
        }
      );
      default = { };
      description = "User Config";
    };
  };
}
