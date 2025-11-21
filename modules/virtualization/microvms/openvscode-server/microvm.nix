{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
let
  vmName = "openvscode-server";
in
{
  imports = [
    ../microvm.nix
  ];
  config = {
    networking.hostName = "${vmName}";

    microvm = {
      hotplugMem = 9216;
      vcpu = 4;
    };

    services.openvscode-server = {
      enable = true;
      package = pkgs.unstable.openvscode-server;
      user = "admin";
      host = "127.0.0.1";
      withoutConnectionToken = true;
      telemetryLevel = "off";
      serverDataDir = "/persist/data";
      userDataDir = "/persist/userdata";
      extensionsDir = "/persist/extensions";
    };

    systemd.tmpfiles.rules = [
      "d /persist/data 0750 admin"
      "d /persist/userdata 0750 admin"
      "d /persist/extensions 0750 admin"
    ];

    environment.persistence."/persist" = {
      directories = [
        "/home"
      ];
    };

    environment.systemPackages = [ pkgs.claude-code ];
    microvm.volumes = lib.mkForce [
      {
        image = "nix-store-overlay.img";
        mountPoint = "/nix/.rw-store";
        size = 25600;
      }
    ];

    services.caddy = {
      enable = true;
      virtualHosts."${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net".extraConfig = ''
        reverse_proxy 127.0.0.1:3000
      '';
    };
  };
}
