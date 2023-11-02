{ options, config, lib, pkgs, inputs, ... }:


with lib;
let
  cfg = config.yomaq.tailscale;
in
{
 config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      authKeyFile = config.age.secrets.tailscaleKey.path;
      extraUpFlags = cfg.extraUpFlags;
      useRoutingFeatures = cfg.useRoutingFeatures;
    };
    environment.persistence."/nix/persistent" = {
      hideMounts = true;
      directories = [
        "/var/lib/tailscale"
      ];
    };
    age.secrets.tailscaleKey.file = ( inputs.self + /secrets/tailscaleKey.age);
 };
}