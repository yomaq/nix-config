{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.yomaq.tailscale;
in
{
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.tailscale = {
        package = pkgs.unstable.tailscale;
        enable = true;
        authKeyFile = cfg.authKeyFile;
        extraUpFlags = cfg.extraUpFlags;
        useRoutingFeatures = cfg.useRoutingFeatures;
        permitCertUid = "caddy";
      };

      environment.persistence."${config.yomaq.impermanence.dontBackup}" = {
        hideMounts = true;
        directories = [ "/var/lib/tailscale" ];
      };
      yomaq.tailscale.tailnetName = "sable-chimaera";
      age.secrets.tailscaleKey.file = (inputs.self + /secrets/tailscaleKey.age);

      environment.systemPackages = with pkgs; [ unstable.tailscale ];

    })
  ];
}
