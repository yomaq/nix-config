{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
let
  vmName = "homepage";
in
{
  imports = [
    ../microvm.nix
    inputs.self.nixosModules.virtualization
  ];
  config = {
    networking.hostName = "${vmName}";

    services.homepage-dashboard.enable = true;
    systemd.services.homepage-dashboard.serviceConfig.Environment = [
      "HOMEPAGE_ALLOWED_HOSTS=${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net"
    ];

    inventory.hosts."${vmName}".glances.homepageMonitor = false;

    yomaq.homepage = {
      enable = true;
      widgets = {
        search = {
          provider = "custom";
          url = "https://azure-searxng.sable-chimaera.ts.net/?q=";
          focus = true;
          target = "_blank";
        };
        openmeteo = {
          label = "Okc";
          latitude = "35.46756";
          longitude = "-97.51643";
          timezone = "America/Chicago";
          units = "Imperial";
          cache = 5;
          format = {
            maximumFractionDigits = 1;
          };
        };
      };
      settings = {
        title = "{{HOMEPAGE_VAR_NAME}}";
        background = {
          blur = "sm";
          saturate = 50;
          brightness = 50;
          opacity = 50;
        };
        color = "slate";
        theme = "dark";
        hideVersion = "true";
        useEqualHeights = true;
        favicon = "https://azure-dufs.sable-chimaera.ts.net/strawberry/favicon.ico";
        statusStyle = "dot";
      };
    };

    systemd.tmpfiles.rules = [
      "d /etc/homepage-dashboard/logs"
      "f /etc/homepage-dashboard/proxmox.yaml"
      "d /var/lib/forgejo-stats 0755 root root"
    ];

    systemd.services.fetch-forgejo-sha = {
      description = "Fetch Forgejo Short SHA";
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.curl}/bin/curl -s "https://forgejo.${config.yomaq.tailscale.tailnetName}.ts.net/api/v1/repos/yomaq/nix-config/commits?limit=1" | \
          ${pkgs.jq}/bin/jq '{sha: .[0].sha[0:8]}' > /var/lib/forgejo-stats/commit.json
      '';
    };

    systemd.timers.fetch-forgejo-sha = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "10s";
        OnUnitActiveSec = "5min";
      };
    };

    services.caddy = {
      enable = true;
      virtualHosts."${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net".extraConfig = ''
        reverse_proxy 127.0.0.1:8082

        handle /forgejo-stats/* {
          root * /var/lib
          file_server
        }
      '';
    };

  };
}
