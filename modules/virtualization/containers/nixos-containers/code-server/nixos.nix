## currently "pkgs.vscode-with-extensions.override" does not appear to be working right now.

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  NAME = "code-server";
  cfg = config.inventory.hosts."${config.networking.hostName}".nixos-containers.${NAME};

  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) dontBackup;
  inherit (config.yomaq.tailscale) tailnetName;
  inherit (config.system) stateVersion;
in
{
  options = {
    inventory.hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.nixos-containers."${NAME}".enable = lib.mkEnableOption (lib.mdDoc "Code Server");
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {

    systemd.tmpfiles.rules = [
      "d ${dontBackup}/nixos-containers/${NAME}/tailscale"
      "d ${dontBackup}/nixos-containers/${NAME}/userdata 0755 admin"
      "d ${dontBackup}/nixos-containers/${NAME}/extensions 0755 admin"
      "d ${dontBackup}/nixos-containers/${NAME}/admin 0755 admin"
    ];

    yomaq.monitorServices.services."container@${hostName}-${NAME}".priority = "medium";

    #will still need to set the network device name manually
    yomaq.network.useBr0 = true;

    containers."${hostName}-${NAME}" = {
      autoStart = true;
      privateNetwork = true;
      hostBridge = "br0"; # Specify the bridge name
      specialArgs = {
        inherit inputs lib;
      };
      bindMounts = {
        "/etc/ssh/${hostName}" = {
          hostPath = "/etc/ssh/${hostName}";
          isReadOnly = true;
        };
        "/var/lib/tailscale/" = {
          hostPath = "${dontBackup}/nixos-containers/${NAME}/tailscale";
          isReadOnly = false;
        };
        "${dontBackup}/nixos-containers/${NAME}/userdata" = {
          hostPath = "${dontBackup}/nixos-containers/${NAME}/userdata";
          isReadOnly = false;
        };
        "${dontBackup}/nixos-containers/${NAME}/extensions" = {
          hostPath = "${dontBackup}/nixos-containers/${NAME}/extensions";
          isReadOnly = false;
        };
        "/home/admin" = {
          hostPath = "${dontBackup}/nixos-containers/${NAME}/admin";
          isReadOnly = false;
        };
      };
      enableTun = true;
      ephemeral = true;
      config = {
        imports = [
          inputs.self.nixosModules.yomaq
        ];
        system.stateVersion = stateVersion;
        age.identityPaths = [ "/etc/ssh/${hostName}" ];

        inventory.hosts."${hostName}-${NAME}".users.enableUsers = [ "admin" ];
        yomaq = {
          suites = {
            container.enable = true;
          };
          tailscale = {
            enable = true;
            extraUpFlags = [
              "--ssh=true"
              "--reset=true"
            ];
          };
        };

        environment.persistence."${dontBackup}".users.admin = lib.mkForce { };

        services.code-server = {
          enable = true;
          user = "admin";
          auth = "none";
          # hashedPassword
          userDataDir = "${dontBackup}/nixos-containers/${NAME}/userdata";
          disableGettingStartedOverride = true;
          disableTelemetry = true;
          disableUpdateCheck = true;
          disableWorkspaceTrust = true;
          extensionsDir = "${dontBackup}/nixos-containers/${NAME}/extensions";
          host = "127.0.0.1";
          port = 3000;
          package = pkgs.vscode-with-extensions.override {
            vscode = pkgs.code-server;
            vscodeExtensions = with pkgs.vscode-extensions; [
              bbenoist.nix
              dracula-theme.theme-dracula
              ms-python.python
            ];
          };
        };

        services.caddy = {
          enable = true;
          virtualHosts."${hostName}-${NAME}.${tailnetName}.ts.net".extraConfig = ''
            reverse_proxy 127.0.0.1:3000
          '';
        };
      };
    };
  };
}
