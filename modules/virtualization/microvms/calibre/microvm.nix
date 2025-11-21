{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
let
  vmName = "calibre";
in
{
  imports = [
    ../microvm.nix
  ];
  config = {
    networking.hostName = "${vmName}";



    services.caddy = {
      enable = true;
      virtualHosts."${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net".extraConfig = ''
        handle_path /calibre-server/* {
          reverse_proxy 127.0.0.1:8080
        }
        reverse_proxy 127.0.0.1:8083
      '';
    };

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
      };
      listen.ip = "127.0.0.1";
    };

    environment.persistence."/persist/save" = {
      directories = [
        "/var/lib/calibre-server"
        "/var/lib/calibre-web"
      ];
    };

  };
}
