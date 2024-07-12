{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.yomaq.nixSettings;
in
{
  imports = [
    inputs.lix.nixosModules.default
  ];
  config = mkIf cfg.enable {
    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };
    systemd.services.nix-daemon.serviceConfig.OOMScoreAdjust = lib.mkDefault 250;
  };
}