{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.yomaq.skhd;
in
{
  options.yomaq.skhd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom skhd module
      '';
    };
  };

  config = lib.mkIf cfg.enable {
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
