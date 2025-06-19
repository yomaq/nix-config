{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.yomaq.ssh;
  hostsCfg = config.inventory.hosts;
  # Generate host entries
  regularHostEntries = lib.mapAttrs (hostname: hostConfig: {
    hostNames = [ hostname ];
    publicKey = hostConfig.publicKey.host;
  }) (lib.filterAttrs (hostname: hostConfig: hostConfig.publicKey.host != "") hostsCfg);
  # Generate initrd host entries
  initrdHostEntries = lib.mapAttrs' (
    hostname: hostConfig:
    lib.nameValuePair "${hostname}-initrd" {
      hostNames = [ "${hostname}-initrd" ];
      publicKey = hostConfig.publicKey.initrd;
    }
  ) (lib.filterAttrs (hostname: hostConfig: hostConfig.publicKey.initrd != "") hostsCfg);
  # Merge
  allHostEntries = regularHostEntries // initrdHostEntries;
in
{
  options = {
    yomaq.ssh = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          enable custom ssh module
        '';
      };
    };
    inventory.hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.publicKey = {
            host = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = ''
                host pubkey
              '';
            };
            initrd = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = ''
                initrd-ssh pubkey
              '';
            };
          };
        }
      );
    };
  };
  config = lib.mkIf cfg.enable {
    programs.ssh.knownHosts = allHostEntries;
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
      };
      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };
  };
}
