{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  ### Set container name and image
  NAME = "pihole";
  IMAGE = "docker.io/pihole/pihole";
  tailscaleIMAGE = "ghcr.io/tailscale/tailscale";


  cfg = config.yomaq.pods.${NAME};
  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) dontBackup;
in
{
  options.yomaq.pods.${NAME} = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom ${NAME} container module
      '';
    };
    agenixSecret = mkOption {
      type = types.path;
      default = (inputs.self + /secrets/${NAME}EnvFile.age);
      description = ''
        path to agenix secret file
      '';
    };
    volumeLocation = mkOption {
      type = types.str;
      default = "${dontBackup}/containers/${NAME}";
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
    tailscale = {
      agenixSecret = mkOption {
        type = types.path;
        default = (inputs.self + /secrets/tailscaleEnvFile.age);
        description = ''
          path to agenix secret file
        '';
      };
      imageVersion = mkOption {
        type = types.str;
        default = "latest";
        description = ''
          container image version
        '';
      };
      TSargs = mkOption {
        type = types.str;
        default = ''
         --exit-node=us-den-wg-102.mullvad.ts.net
         serve <https+insecure://localhost:80>
         '';
        description = ''
          TS_Extra_ARGS env var
        '';
      };
      TShostname = mkOption {
        type = types.str;
        default = "${hostName}_TS_${NAME}";
        description = ''
          TS_HOSTNAME env var
        '';
      };
    };
  };




  config = mkIf cfg.enable {

  networking.firewall.allowedTCPPorts = [53];
  networking.firewall.allowedUDPPorts = [53];

    ### agenix secrets for container
    age.secrets."${NAME}EnvFile".file = cfg.agenixSecret;
    age.secrets."tailscaleEnvFile".file = cfg.tailscale.agenixSecret;

  # make the directories where the volumes are stored
  # it says "tmpfiles" but we don't add rules to remove the tmp file, so its... not tmp?
  # https://discourse.nixos.org/t/creating-directories-and-files-declararively/9349
  # storing volumes in the nix directory because we assume impermanance is wiping root
    systemd.tmpfiles.rules = [
      # pihole
      "d ${cfg.volumeLocation}/etc-pihole 0755 root root"
      "d ${cfg.volumeLocation}/etc-dnsmasq.d 0755 root root"
      # tailscale
      "d ${cfg.volumeLocation}/TSdata-lib 0755 root root"
      "d ${cfg.volumeLocation}/TSdev-net-tun 0755 root root"
    ];


    virtualisation.oci-containers.containers = {
### pihole container
      "${NAME}" = {
        image = "${IMAGE}:${cfg.imageVersion}";
        autoStart = true;
        environment = {
          "TZ" = "America/Chicago";
        };
        environmentFiles = [
           # need to set "WEBPASSWORD=password" in agenix and import here
          config.age.secrets."${NAME}EnvFile".path
        ];
        volumes = [
          "${cfg.volumeLocation}/etc-pihole:/etc/pihole"
          "${cfg.volumeLocation}/etc-dnsmasq.d:/etc/dnsmasq.d"
        ];
        extraOptions = [
          "--pull=newer"
          "--network=container:TS${NAME}"
        ];
      };
### tailscale container
      "TS${NAME}" = {
        image = "${tailscaleIMAGE}:${cfg.tailscale.imageVersion}";
        autoStart = true;
        environment = {
        "TS_HOSTNAME" =cfg.tailscale.TShostname;
        "TS_STATE_DIR"= "/var/lib/tailscale";
        "TS_EXTRA_ARGS" = cfg.tailscale.TSargs;
        "TS_ACCEPT_DNS" = "true";
        };
        environmentFiles = [
          # need to set "TS_AUTHKEY=key" in agenix and import here
          config.age.secrets."tailscaleEnvFile".path
        ];
        volumes = [
          "${cfg.volumeLocation}/TSdata-lib:/var/lib"
          "${cfg.volumeLocation}/TSdev-net-tun:/dev/net/tun"
        ];
        extraOptions = [
          "--pull=newer"
          "--network=host"
          "--cap-add=NET_ADMIN"
          "--cap-add=NET_RAW"
        ];
      };
    };
  };
}