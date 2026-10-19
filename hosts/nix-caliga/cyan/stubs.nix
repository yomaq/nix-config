{ lib, pkgs, ... }:

{
  options = {
    networking.hostName = lib.mkOption {
      type = lib.types.str;
      default = "";
    };

    boot.kernelPackages = lib.mkOption {
      type = lib.types.raw;
      default = pkgs.linuxPackages;
    };

    yomaq.impermanence.dontBackup = lib.mkOption {
      type = lib.types.str;
      default = "/persist";
    };

    environment.persistence = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
    };

    security.sudo.extraRules = lib.mkOption {
      type = lib.types.listOf lib.types.unspecified;
      default = [ ];
    };

    users.users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.openssh.authorizedKeys.keys = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        }
      );
    };
  };

  config = {
    networking.hostName = "cyan";
  };
}
