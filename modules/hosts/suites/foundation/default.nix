{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.yomaq.suites.foundation;
in
{
  options.yomaq.suites.foundation = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = '''';
    };
  };

  config = lib.mkIf cfg.enable {
    yomaq = {
      zsh.enable = true;
      agenix.enable = true;
      nixSettings.enable = true;
      tailscale.enable = true;
      network.basics = true;
    };
  };
}
