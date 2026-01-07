{
  config,
  lib,
  inputs,
  ...
}:
let
  NAME = "calibre-web";
  cfg = config.inventory.hosts."${config.networking.hostName}".nixos-containers.${NAME};

  inherit (config.networking) hostName;
  inherit (config.yomaq.impermanence) backup;
  inherit (config.yomaq.impermanence) dontBackup;
  inherit (config.yomaq.tailscale) tailnetName;
  inherit (config.system) stateVersion;
in
{
  options = {
    inventory.hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.nixos-containers."${NAME}".enable = lib.mkEnableOption (lib.mdDoc "${NAME} Server");
        }
      );
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {

      systemd.tmpfiles.rules = [
        "d ${backup}/nixos-containers/${NAME}/data 0755 admin"
        "d ${backup}/nixos-containers/${NAME}/data/calibre-server 0755 admin"
        "d ${dontBackup}/nixos-containers/${NAME}/tailscale"
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
          "/var/lib/calibre-web" = {
            hostPath = "${backup}/nixos-containers/${NAME}/data";
            isReadOnly = false;
          };
          "/var/lib/calibre-server" = {
            hostPath = "${backup}/nixos-containers/${NAME}/data/calibre-server";
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

          services.calibre-server = {
            enable = true;
            auth = {
              enable = true;
              mode = "basic";
              userDb = "/var/lib/calibre-server/calibre_users.sqlite";
            };
            user = "calibre-web";
            group = "calibre-web";
            libraries = [
              "/var/lib/calibre-server/"
            ];
            extraFlags = [
              "--url-prefix=/calibre-server"
            ];
          };

          users.users = {
            calibre-web = {
              home = "/var/lib/calibre-server";
              createHome = true;
            };
          };

          services.calibre-web = {
            enable = true;
            options = {
              enableBookUploading = true;
              # reverseProxyAuth = {
              #   header = "X-Webauth-Login";
              #   enable = true;
              # };
            };
            listen.ip = "127.0.0.1";
          };

          # services.tailscaleAuth = {
          #   enable = true;
          #   group = "caddy";
          #   user = "caddy";
          # };

          services.caddy = {
            enable = true;
            virtualHosts."${hostName}-${NAME}.${tailnetName}.ts.net".extraConfig = ''
              handle_path /calibre-server/* {
                reverse_proxy 127.0.0.1:8080
              }
              reverse_proxy 127.0.0.1:8083
            '';
            # forward_auth unix//run/tailscale-nginx-auth/tailscale-nginx-auth.sock {
            #     uri /auth
            #     header_up Remote-Addr {remote_host}
            #     header_up Remote-Port {remote_port}
            #     header_up Original-URI {uri}
            #     copy_headers {
            #         Tailscale-Login>X-Webauth-Login
            #     }
            # }

          };
        };
      };
    })
    (lib.mkIf config.yomaq.gatus.enable {
      yomaq.gatus.endpoints =
        map
          (host: {
            name = "${host}-${NAME}";
            group = "webapps";
            url = "https://${host}-${NAME}.${config.yomaq.tailscale.tailnetName}.ts.net";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [
              {
                type = "ntfy";
                failureThreshold = 3;
                description = "healthcheck failed";
              }
            ];
          })
          (
            builtins.filter (host: config.inventory.hosts.${host}.nixos-containers."${NAME}".enable or false) (
              builtins.attrNames config.inventory.hosts
            )
          );
    })
    (lib.mkIf config.yomaq.homepage.enable {
      yomaq.homepage.groups.services = builtins.listToAttrs (
        map
          (host: {
            name = "${NAME} - ${host}";
            value = {
              icon = "mdi-book";
              href = "https://${host}-${NAME}.${tailnetName}.ts.net/";
              siteMonitor = "https://${host}-${NAME}.${tailnetName}.ts.net/";
            };
          })
          (
            builtins.filter (host: config.inventory.hosts.${host}.nixos-containers."${NAME}".enable or false) (
              builtins.attrNames config.inventory.hosts
            )
          )
      );
    })
  ];
}
