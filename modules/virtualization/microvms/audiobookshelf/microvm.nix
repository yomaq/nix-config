{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
let
  vmName = "audiobookshelf";
in
{
  imports = [
    ../microvm.nix
  ];
  config = {
    networking.hostName = "${vmName}";

    services.audiobookshelf = {
      enable = true;
    };

    services.caddy = {
      enable = true;
      virtualHosts."${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net".extraConfig = ''
        reverse_proxy 127.0.0.1:8000
      '';
    };

    environment.persistence."/persist/save" =  {
      directories = [
        "/var/lib/audiobookshelf"
      ];
    };

  };
}
