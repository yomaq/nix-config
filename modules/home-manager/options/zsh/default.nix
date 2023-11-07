{ options, config, lib, pkgs, ... }:

with lib;
let
  cfg = config.yomaq.zsh;
in
{
  options.yomaq.zsh = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom zsh module
      '';
    };
  };

  config = mkIf cfg.enable {
    zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      initExtra = "for FILE in ~/.zshrcs/*; do source $FILE; done";
      oh-my-zsh = {
        enable = true;
        theme = "darkblood";
        plugins = [
          "kubectl" 
        ];
      };
    };
  };
}