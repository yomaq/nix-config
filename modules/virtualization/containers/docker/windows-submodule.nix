{
  config,
  lib,
  ...
}:
let
  ### Set container name and image
  NAME = "windows";
  IMAGE = "docker.io/dockurr/windows";

  cfg = config.inventory.hosts."${config.networking.hostName}".pods.${NAME};

  inherit (config.yomaq.impermanence) dontBackup;

  containerOpts =
    { name, ... }:
    {
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            enable custom ${NAME} container module
          '';
        };
        volumeLocation = lib.mkOption {
          type = lib.types.str;
          default = "${dontBackup}/containers/windows/${name}";
          description = ''
            path to store container volumes
          '';
        };
        imageVersion = lib.mkOption {
          type = lib.types.str;
          default = "latest";
          description = ''
            container image version
          '';
        };
        version = lib.mkOption {
          type = lib.types.str;
          default = "win11";
          description = ''
            Version of Windows to create
          '';
        };
        envVariables = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {
            RAM_SIZE = "8G";
            CPU_CORES = "4";
          };
          description = ''
            set custom environment variables for the windows container
          '';
        };
      };
    };
  mkContainer = name: cfg: {
    image = "${IMAGE}:${cfg.imageVersion}";
    autoStart = true;
    environment = lib.mkMerge [
      cfg.envVariables
      { "VERSION" = "${cfg.version}"; }
    ];
    volumes = [ "${cfg.volumeLocation}/storage:/storage" ];
    extraOptions = [
      "--pull=always"
      "--network=container:TS${name}"
      "--device=/dev/kvm"
      "--cap-add=NET_ADMIN"
    ];
    # user = "4000:4000";
  };
  mkTmpfilesRules = _name: cfg: [ "d ${cfg.volumeLocation}/storage 0755 root root" ];
  containersList = lib.attrNames cfg;
  renameTScontainers = map (a: "TS" + a) containersList;

in
# homepageServices = name:  [{
#     "${name}" = {
#       icon = "si-minecraft";
#       href = "https://${hostName}-${name}.${tailnetName}.ts.net";
#       widget = {
#         type = "gamedig";
#         serverType = "minecraftbe";
#         url = "udp://${hostName}-${name}.${tailnetName}.ts.net:19132";
#         fields = [ "status" "players" "ping" ];
#       };
#   };
# }];
{
  options = {
    inventory.hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.pods = {
            windows = lib.mkOption {
              default = { };
              type = with lib.types; attrsOf (submodule containerOpts);
              example = { };
              description = lib.mdDoc ''
                Windows Docker VM
              '';
            };
          };
        }
      );
    };
  };
  config = lib.mkIf (cfg != { }) {
    yomaq.pods.tailscaled = lib.genAttrs renameTScontainers (_container: {
      tags = [ "tag:windowsindocker" ];
      TSserve = {
        "/" = "http://127.0.0.1:8006";
      };
    });
    systemd.tmpfiles.rules = lib.flatten (lib.mapAttrsToList (name: cfg: mkTmpfilesRules name cfg) cfg);
    virtualisation.oci-containers.containers = lib.mapAttrs mkContainer cfg;
    # yomaq.homepage.services = [{minecraft = lib.flatten (map homepageServices containersList);}];
    # yomaq.homepage.settings.layout.minecraft.tab = "Services";

    yomaq.monitorServices.services."docker-${NAME}".priority = "medium";
  };
}
