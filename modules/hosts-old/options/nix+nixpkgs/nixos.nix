{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.yomaq.nixSettings;
in
{

  config = mkIf cfg.enable {
    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };
  };
}