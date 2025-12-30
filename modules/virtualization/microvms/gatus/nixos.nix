{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
let
  vmName = "gatus";
  vmDeployedOnHost = builtins.any (
    host: builtins.elem vmName (config.inventory.hosts.${host}.microvms or [ ])
  ) (builtins.attrNames config.inventory.hosts);
in
{
  config = lib.mkIf (config.yomaq.homepage.enable && vmDeployedOnHost) {
    yomaq.homepage.groups.services.${vmName} = {
      icon = "mdi-list-status";
      href = "https://${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net/";
      siteMonitor = "https://${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net/";
    };
  };
}
