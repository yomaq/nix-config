{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
let
  vmName = "homepage";
  vmDeployedOnThisHost = builtins.elem vmName (
    config.inventory.hosts.${config.networking.hostName}.microvms or [ ]
  );
  vmDeployedOnHost = builtins.any (
    host: builtins.elem vmName (config.inventory.hosts.${host}.microvms or [ ])
  ) (builtins.attrNames config.inventory.hosts);
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
    (lib.mkIf vmDeployedOnThisHost {
      age.secrets."homepage".file = (inputs.self + /secrets/homepage.age);
    })
  ];
}
