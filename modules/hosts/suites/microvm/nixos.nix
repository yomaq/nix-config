{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  cfg = config.yomaq.suites.microvm;
in
{
  options.yomaq.suites.microvm = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''basic configuration that should be set for all microvms'';
    };
  };

  config = lib.mkIf cfg.enable {
    yomaq = {
      timezone.central = true;
      zsh.enable = true;
      ssh.enable = true;
      tailscale = {
        enable = true;
        extraUpFlags = [
          "--ssh=true"
          "--reset=true"
        ];
      };
    };
    systemd.network.enable = true;
    inventory.hosts."${config.networking.hostName}".users.enableUsers = [ "admin" ];
    nixpkgs.overlays = [ 
      inputs.agenix.overlays.default 
      inputs.self.overlays.pkgs-unstable
    ];
    microvm.host.enable = false;
  };
}
