{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
let
  vmName = "ntfy";
in
{
  imports = [
    ../microvm.nix
  ];
  config = {
    networking.hostName = "${vmName}";

    services.ntfy-sh = {
      enable = true;
      settings = {
        base-url = "https://${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net";
        listen-http = ":8080";
        upstream-base-url = "https://ntfy.sh";
      };
    };

    services.caddy = {
      enable = true;
      virtualHosts."${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net".extraConfig = ''
        reverse_proxy 127.0.0.1:8080
      '';
    };

  };
}
