{ options, config, lib, pkgs, ... }:

with lib;
let
  cfg = config.yomaq.skhd;
in
{
  options.yomaq.skhd = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom skhd module
      '';
    };
  };

  config = mkIf cfg.enable {
    services = {
      skhd = {
        enable = true;
        skhdConfig = ''
          alt + cmd - return  : open -na ${pkgs.alacritty}/Applications/Alacritty.app
        '';
      };
    };
  };
}
