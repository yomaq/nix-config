{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
let
  vmName = "forgejo";
  vmDeployedOnHost = builtins.any
    (host: builtins.elem vmName (config.inventory.hosts.${host}.microvms or []))
    (builtins.attrNames config.inventory.hosts);
  vmDeployedOnThisHost = builtins.elem vmName
    (config.inventory.hosts.${config.networking.hostName}.microvms or []);
in
{
  config = lib.mkMerge [
    (lib.mkIf (config.yomaq.gatus.enable && vmDeployedOnHost) {
      yomaq.gatus.endpoints = [
        {
          name = "${vmName}";
          group = "webapps";
          url = "https://${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net";
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [
            {
              type = "ntfy";
              failureThreshold = 3;
              description = "healthcheck failed";
            }
          ];
        }
      ];
    })
    (lib.mkIf (config.yomaq.homepage.enable && vmDeployedOnHost) {
      yomaq.homepage.groups.services.${vmName} = {
        icon = "si-forgejo";
        href = "https://${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net/";
        siteMonitor = "https://${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net/";
      };
    })
    (lib.mkIf vmDeployedOnThisHost {
      age.secrets.forgejoRunnerToken.file = (inputs.self + /secrets/forgejoRunnerToken.age);
    })
  ];
}