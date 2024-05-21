{ options, config, lib, pkgs, inputs, ... }:


with lib;
let
  cfg = config.yomaq.tailscale;

  inherit (config.networking) hostName;
in
{
 config = mkMerge [
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
      directories = [
        "/var/lib/tailscale"
      ];
    };
    yomaq.tailscale.tailnetName = "sable-chimaera";
    age.secrets.tailscaleKey.file = ( inputs.self + /secrets/tailscaleKey.age);

    yomaq.homepage.groups.services."Flake Nixos Hosts" = [{
      " " = {
        href = "http://${hostName}.${cfg.tailnetName}.ts.net";
        ping = "${hostName}.${cfg.tailnetName}.ts.net";
        description = "${hostName}";
      };
    }];
    yomaq.homepage.settings = {
      layout = {
        "Flake Nixos Hosts" = {
          tab = "Status Monitor";
          style = "row";
          columns = 8;
        };
      };
    };


  })
  (lib.mkIf cfg.preApprovedSshAuthkey {
    age.secrets.tailscaleOAuthKeyAcceptSsh.file = ( inputs.self + /secrets/tailscaleOAuthKeyAcceptSsh.age);
  })];
}