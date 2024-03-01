{ options, config, lib, pkgs, inputs, ... }:


with lib;
let
  cfg = config.yomaq.tailscale;
in
{
 config = mkMerge [
  (lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      authKeyFile = cfg.authKeyFile;
      extraUpFlags = cfg.extraUpFlags;
      useRoutingFeatures = cfg.useRoutingFeatures;
    };
    environment.persistence."${config.yomaq.impermanence.dontBackup}" = {
      hideMounts = true;
      directories = [
        "/var/lib/tailscale"
      ];
    };
    yomaq.tailscale.tailnetName = "sable-chimaera";
    age.secrets.tailscaleKey.file = ( inputs.self + /secrets/tailscaleKey.age);
  })
  (lib.mkIf cfg.preApprovedSshAuthkey {
    age.secrets.tailscaleKeyAcceptSsh.file = ( inputs.self + /secrets/tailscaleKeyAcceptSsh.age);
  })]
}