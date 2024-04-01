{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  ### Set container name and image
  NAME = "windows";
  IMAGE = "docker.io/dockurr/windows";

  cfg = config.yomaq.pods.windows;
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.impermanence) dontBackup;
  inherit (config.yomaq.tailscale) tailnetName;


  containerOpts = { name, config, ... }:
  {
    options = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          enable custom ${NAME} container module
        '';
      };
      volumeLocation = mkOption {
        type = types.str;
        default = "${dontBackup}/containers/windows/${name}";
        description = ''
          path to store container volumes
        '';
      };
      imageVersion = mkOption {
        type = types.str;
        default = "latest";
        description = ''
          container image version
        '';
      };
      version = mkOption {
        type = types.str;
        default = "win11";
        description = ''
          Version of Windows to create
        '';
      };
      envVariables = mkOption {
        type = types.attrsOf types.str;
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
    volumes = ["${cfg.volumeLocation}/storage:/storage"];
    extraOptions = [
      "--pull=always"
      "--network=container:TS${name}"
      "--device=/dev/kvm"
      "--cap-add=NET_ADMIN"
    ];
    # user = "4000:4000";
  };
  mkTmpfilesRules = name: cfg: [
    "d ${cfg.volumeLocation}/storage 0755 root root"
  ];
  containersList = attrNames cfg;
  renameTScontainers = map (a: "TS" + a) containersList;

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
in
{
  options.yomaq.pods = {
    windows = mkOption {
      default = {};
      type = with types; attrsOf (submodule containerOpts);
      example = {};
      description = lib.mdDoc ''
        Windows Docker VM
      '';
    };
  };
  config = mkIf (cfg != {}) {
    yomaq.pods.tailscaled = lib.genAttrs renameTScontainers (container: { tags = ["tag:windowsindocker"]; TSserve =  {"/" = "http://127.0.0.1:8006";};});
    systemd.tmpfiles.rules = lib.flatten ( lib.mapAttrsToList (name: cfg: mkTmpfilesRules name cfg) cfg);
    virtualisation.oci-containers.containers = lib.mapAttrs mkContainer cfg;
    # yomaq.homepage.services = [{minecraft = lib.flatten (map homepageServices containersList);}];
    # yomaq.homepage.settings.layout.minecraft.tab = "Services";
  };
}