{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.yomaq.glances;

  inherit (config.networking) hostName;
  inherit (config.yomaq.tailscale) tailnetName;
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
        # HOMEPAGE_CONFIG_DIR = "/var/lib/homepage-dashboard";
        # PORT = "${toString cfg.listenPort}";
      };

      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        StateDirectory = "glances";
        ExecStart = "${lib.getExe cfg.package} -w";
        Restart = "on-failure";
      };
    };

    # systemd.tmpfiles.rules = lib.flatten [
    #   ("L+ /var/lib/homepage-dashboard/settings.yaml 755 root root - ${(pkgs.formats.yaml { }).generate "settings.yaml" cfg.settings}")
    # ];

    yomaq.homepage.services = [{ "${hostName}" =  [
      {CPU = {
        href = "http://${hostName}.${tailnetName}.ts.net:61208";
        widget = {
          type = "glances";
          url = "http://${hostName}.${tailnetName}.ts.net:61208";
          metric = "cpu";
        };
      };}
      {INFO = {
        href = "http://${hostName}.${tailnetName}.ts.net:61208";
        widget = {
          type = "glances";
          url = "http://${hostName}.${tailnetName}.ts.net:61208";
          metric = "info";
        };
      };}
      {PersistSave = {
        href = "http://${hostName}.${tailnetName}.ts.net:61208";
        widget = {
          type = "glances";
          url = "http://${hostName}.${tailnetName}.ts.net:61208";
          metric = "fs:/persist/save";
        };
      };}
      {Processes = {
        href = "http://${hostName}.${tailnetName}.ts.net:61208";
        widget = {
          type = "glances";
          url = "http://${hostName}.${tailnetName}.ts.net:61208";
          metric = "process";
        };
      };}
    ];}];
    yomaq.homepage.settings = {
      layout = {
        "${hostName}" = {
          tab = "Glances";
          style = "row";
          columns = 4;
        };
      };
    };
  };
}