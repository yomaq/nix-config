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
    # wow... this is so much more simple than what I did before.
    # not using services.gatus directly just in case I end up wanting a separate gatus server for something else
    services.gatus.settings.endpoints = cfg.endpoints;
    services.gatus.settings.external-endpoints = cfg.externalEndpoints;
  };
}
