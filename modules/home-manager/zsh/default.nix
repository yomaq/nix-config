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
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh = {
        enable = true;
        theme = "darkblood";
        plugins = [
          "kubectl" 
        ];
      };
      envExtra = ''
          EDITOR=vim
          ${lib.optionalString (pkgs.system == "aarch64-darwin") "export PATH=/opt/homebrew/bin:$PATH"}
      '';
    };
  };
}