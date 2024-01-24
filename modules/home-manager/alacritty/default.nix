{ options, config, lib, pkgs, inputs, ... }:
let
  cfg = config.yomaq.alacritty;
in
{
  imports = [];
  options.yomaq.alacritty = {
    enable = with lib; mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom alacritty module
      '';
    };
  };
 config = lib.mkIf cfg.enable {
    programs = {
      alacritty = {
        enable = true;
        settings = {
          window = {
            opacity = "0.8";
            decorations = "None";
            colors = {
              # primary = {
              #   background = "#000000";
              #   foreground = "#ffffff";
              # };
              normal = {
                black =   "0x2c2525";
                red =     "0xfd688";
                green =   "0xadda78";
                yellow =  "0xf9cc6c";
                blue =    "0xf38d70";
                magenta = "0xa8a9eb";
                cyan =    "0x85dacc";
                white =   "0xfff1f3";
              };
              bright = {
                black = "0x72696a";
                red = "0xfd6883";
                green = "0xadda78";
                yellow = "0xf9cc6c";
                blue = "0xf38d70";
                magenta = "0xa8a9eb";
                cyan = "0x85dacc";
                white = "0xfff1f3";
              };
            };
          };
        };
      };
    };
 };
}
