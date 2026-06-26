{ lib, ... }:

{
  options = {
    networking.hostName = lib.mkOption {
      type = lib.types.str;
      default = "";
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
