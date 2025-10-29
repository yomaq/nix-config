{
  config,
  lib,
  ...
}:
let
  cfg = config.yomaq.suites.container;
in
{
  options.yomaq.suites.container = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = '''';
    };
  };

  config = lib.mkIf cfg.enable {
    inventory = lib.mkForce { };
    yomaq = {
      zsh.enable = true;
      agenix.enable = true;
      nixSettings.enable = true;
      tailscale.enable = true;
    };
    networking.useHostResolvConf = lib.mkForce false;
    networking.useDHCP = lib.mkForce true;
    microvm.host.enable = false;

    environment.persistence."/persist/save".enableWarnings = lib.mkForce false;
    environment.persistence."/persist".enableWarnings = lib.mkForce false;
  };
}
