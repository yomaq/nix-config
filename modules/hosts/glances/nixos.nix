{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.yomaq.glances;
in
{
  options = {
    yomaq.glances = {
      enable = lib.mkEnableOption (lib.mdDoc "Glances Server");
      package = lib.mkPackageOptionMD pkgs "glances" { };
      # listenPort = lib.mkOption {
      #   type = lib.types.int;
      #   default = 8082;
      #   description = lib.mdDoc "Port for Homepage to bind to.";
      # };
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.glances = {
      description = "Glances Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        HOMEPAGE_CONFIG_DIR = "/var/lib/homepage-dashboard";
        PORT = "${toString cfg.listenPort}";
      };

      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        StateDirectory = "glances";
        ExecStart = "${lib.getExe cfg.package} -w";
        Restart = "on-failure";
      }
    };

    # systemd.tmpfiles.rules = lib.flatten [
    #   ("L+ /var/lib/homepage-dashboard/settings.yaml 755 root root - ${(pkgs.formats.yaml { }).generate "settings.yaml" cfg.settings}")
    # ];
  };
}