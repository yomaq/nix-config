{
  config,
  lib,
  ...
}:
let
  cfg = config.yomaq.suites.basics;
in
{
  imports = [ ];
  config = lib.mkIf cfg.enable {
    yomaq = {
      skhd.enable = true;
    };
  };
}
