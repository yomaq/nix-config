{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
let
  vmName = "immich";
  baseDir = "/var/lib/microvms/${hostName}";
  hostName = config.networking.hostName;
in
{
  imports = [
    ../microvm.nix
  ];
  config = {
    networking.hostName = "${vmName}";

    microvm = {
      hotplugMem = 3584;
      vcpu = 4;
    };
    microvm.shares = [
      {
        source = "${config.yomaq.impermanence.backupStorage}/microvms/${vmName}";
        mountPoint = "/storage/save";
        tag = "storageSave";
        proto = "virtiofs";
        socket = "${baseDir}/storageSave.socket";
      }
    ];

    age.secrets.immichOAuthClientId.file = (inputs.self + /secrets/immichOAuthClientId.age);
    age.secrets.immichOAuthClientSecret.file = (inputs.self + /secrets/immichOAuthClientSecret.age);

    services.immich = {
      enable = true;
      host = "127.0.0.1";
      database.enable = true;
      redis.enable = true;
      machine-learning.enable = true;
      settings = {
        server.externalDomain = "https://${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net";
        oauth = {
          enabled = true;
          issuerUrl = config.yomaq.tailscale.tsidpUrl;
          clientId._secret = config.age.secrets.immichOAuthClientId.path;
          clientSecret._secret = config.age.secrets.immichOAuthClientSecret.path;
          # autoRegister = true;
          buttonText = "Log in with Tailscale";
        };
      };
    };

    services.caddy = {
      enable = true;
      virtualHosts."${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net".extraConfig = ''
        reverse_proxy 127.0.0.1:2283
      '';
    };

    environment.persistence."/storage/save" = {
      directories = [
        "/var/lib/postgresql"
        "/var/lib/immich"
      ];
    };
  };
}
