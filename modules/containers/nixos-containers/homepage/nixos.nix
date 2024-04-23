{ config, lib, pkgs, inputs, modulesPath, ... }:
let

  NAME = "homepage";

  cfg = config.yomaq.nixos-containers."${NAME}";

  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.impermanence) dontBackup;
  inherit (config.yomaq.impermanence) backupStorage;
  inherit (config.yomaq.tailscale) tailnetName;
  inherit (config.system) stateVersion;

in
{
  options.yomaq.nixos-containers."${NAME}" = {
    enable = lib.mkEnableOption (lib.mdDoc "${NAME} Server");
    storage = lib.mkOption {
      description = "persistent file location";
      type = lib.types.str;
      default = dontBackup;
    };
  };

  config = lib.mkIf cfg.enable {

    yomaq.homepage.enable = true;

    systemd.tmpfiles.rules = [
      "d ${cfg.storage}/nixos-containers/${NAME}/tailscale"
    ];

    #will still need to set the network device name manually
    yomaq.network.useBr0 = true;

    containers."${hostName}-${NAME}" = {
      autoStart = true;
      privateNetwork = true;
      hostBridge = "br0"; # Specify the bridge name
      specialArgs = { inherit inputs; };
      bindMounts = { 
        "/etc/ssh/${hostName}" = { 
          hostPath = "/etc/ssh/${hostName}";
          isReadOnly = true; 
        };
        "/var/lib/tailscale" = {
          hostPath = "${cfg.storage}/nixos-containers/${NAME}/tailscale";
          isReadOnly = false; 
        };
      };
      enableTun = true;
      ephemeral = true;
      config = {
        imports = [
          inputs.self.nixosModules.yomaq
          (inputs.self + /users/admin)
          ];
        system.stateVersion = stateVersion;
        age.identityPaths = ["/etc/ssh/${hostName}"];

        yomaq = {
          tailscale.extraUpFlags = ["--ssh=true" "--reset=true"];
          suites.container.enable = true;
          homepage-dashboard.enable = true;
          homepage.enable = true;
        };
        systemd.tmpfiles.rules = [
          "d /etc/homepage-dashboard/logs"
        ];
        services.caddy = {
          enable = true;
          virtualHosts."${hostName}-${NAME}.${tailnetName}.ts.net".extraConfig = ''
            reverse_proxy 127.0.0.1:8082
          '';
        };
      };
    };
  };
}