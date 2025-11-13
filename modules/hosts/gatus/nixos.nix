{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.yomaq.gatus;
in
{
  options.yomaq.gatus = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Gatus configuration";
    };
    url = lib.mkOption {
      type = lib.types.str;
      description = "gatus server url";
      default = "https://ntfy.${config.yomaq.tailscale.tailnetName}.ts.net";
    };
    endpoints = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "gatus config for endpoints";
      default = [ ];
    };
    externalEndpoints = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "gatus config for external endpoints";
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    services.gatus.settings.endpoints = cfg.endpoints;
    services.gatus.settings.external-endpoints = cfg.externalEndpoints;
  };
}
