{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.yomaq.zsh;
in
{
  options.yomaq.zsh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom zsh module
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh = {
        enable = true;
        theme = "darkblood";
        plugins = [ "kubectl" ];
      };
      envExtra = ''
        EDITOR=vim
        ${lib.optionalString (pkgs.stdenv.hostPlatform.system == "aarch64-darwin") "export PATH=/opt/homebrew/bin:$PATH"}
      '';
    };
  };
}
