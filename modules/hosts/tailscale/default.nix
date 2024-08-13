{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

# why am I not just using the tailscale service directly? ... idk, it auto configures the authKeyFile?

let
  cfg = config.yomaq.tailscale;
in
{
  options.yomaq.tailscale = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom tailscale module
      '';
    };
    extraUpFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "--ssh=true"
        "--reset=true"
        "--accept-dns=true"
      ];
      description = ''
        Extra flags to pass to tailscale up.
      '';
    };
    useRoutingFeatures = lib.mkOption {
      type = lib.types.enum [
        "none"
        "client"
        "server"
        "both"
      ];
      default = "none";
      example = "server";
      description = lib.mdDoc ''
        Enables settings required for Tailscale's routing features like subnet routers and exit nodes.

        To use these these features, you will still need to call `sudo tailscale up` with the relevant flags like `--advertise-exit-node` and `--exit-node`.

        When set to `client` or `both`, reverse path filtering will be set to loose instead of strict.
        When set to `server` or `both`, IP forwarding will be enabled.
      '';
    };
    tailnetName = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        The name of the tailnet
      '';
    };
    authKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = "${config.age.secrets.tailscaleKey.path}";
      description = ''
        allow you to specify a key, or set null to disable
      '';
    };
    preApprovedSshAuthkey = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        decrypt pre-approved ssh authkey
      '';
    };
  };
}
