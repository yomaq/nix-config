{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
let
  vmName = "gatus";
in
{
  imports = [
    ../microvm.nix
    inputs.self.nixosModules.virtualization
  ];
  config = {
    networking.hostName = "${vmName}";

    yomaq.gatus.enable = true;
    systemd.services.gatus.serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
    services.gatus = {
      enable = true;
      settings = {
        web.port = 8080;
        storage = {
          type = "sqlite";
          path = "/var/lib/gatus/data.db";
        };
        # external-endpoints = [{
        #   name = "ext-ep-test";
        #   group = "test";
        #   token = "potato";
        # }];
        # curl -X POST \
        #   https://azure-gatus.sable-chimaera.ts.net/api/v1/endpoints/test_ext-ep-test/external\?success\=true\&error\= \
        #   -H 'Authorization: Bearer potato'

        alerting = {
          ntfy = {
            url = "${config.yomaq.ntfy.ntfyUrl}";
            topic = "${config.yomaq.ntfy.defaultTopic}";
            priority = 3;
            default-alert = {
              enable = true;
              failure-threshold = 10;
              success-threshold = 10;
              send-on-resolved = true;
            };
          };
        };
      };
    };

    services.caddy = {
      enable = true;
      virtualHosts."${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net".extraConfig = ''
        reverse_proxy 127.0.0.1:8080
      '';
    };

    environment.persistence."/persist" = lib.mkForce {
      directories = [
        "/var/lib/"
      ];
    };

  };
}
