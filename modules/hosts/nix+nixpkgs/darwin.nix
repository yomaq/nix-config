{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.yomaq.nixSettings;
in
{
  config = lib.mkIf cfg.enable {
    nix = {
      gc = {
        automatic = true;
        interval.Hour = 1;
        options = "--delete-older-than 30d";
      };
      #Nix Store config, hard linking identical dependancies etc.
      settings = {
        allowed-users = [ "carln" ];
      };
    };
    services.nix-daemon.enable = true;
    #At the time of making the config nix breaks when darwin documentation is enabled.
    documentation.enable = false;
  };
}
