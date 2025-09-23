{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.yomaq.suites.basic;
in
{
  imports = [ ];
  options.yomaq.suites.basic = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom suite
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    yomaq = {
      comma.enable = true;
      bash.enable = true;
      tmux.enable = true;
      zsh.enable = true;
      direnv.enable = true;
      spotlight-links.enable = true;
    };
  };
}
