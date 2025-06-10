{
  config,
  lib,
  ...
}:
let
  cfg = config.yomaq.zsh;
in
{
  config = lib.mkIf cfg.enable { programs.zsh.enable = true; };
}
