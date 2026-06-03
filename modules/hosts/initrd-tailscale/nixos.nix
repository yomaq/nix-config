# wanted to use tailscale ssh, but currently don't know how to persist the host keys.
# currently using standard ssh over the tailnet for unlocking, which lets me keep the initrd host key in the main OS and load it into initrd.
#
# Still plan on going back over this and basing it as much as possible on the normal upstream tailscale service.
# OAuth keys work now so no more need to rotate keys every 90 days.

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.yomaq.initrd-tailscale;
in
{
  options = {
    yomaq.initrd-tailscale = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Tailscale during initrd.
        '';
      };

      package = lib.mkPackageOption pkgs "tailscale" { };

      oauthKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = "${config.age.secrets.tailscaleOAuthKeyAcceptSsh.path}";
        example = "/run/secrets/tailscale_key";
        description = ''
          A file containing the Tailscale OAuth client secret. Requires advertising a tag on the OAuth key.
        '';
      };

      extraUpFlags = lib.mkOption {
        description = "Extra flags to pass to {command}`tailscale up`.";
        type = lib.types.listOf lib.types.str;
        default = [
          "--advertise-tags=tag:acceptssh"
        ];
        example = [ "--ssh" ];
      };
    };
  };
  config =
    lib.mkMerge [
      (lib.mkIf (config.boot.initrd.network.enable && !config.yomaq.disks.amReinstalling && cfg.enable) {

        boot.initrd.kernelModules = [ "tun" ];

        boot.initrd.systemd.network.wait-online.anyInterface = true;

        age.secrets.tailscaleOAuthKeyAcceptSsh.file = (
          inputs.self + /secrets/tailscaleOAuthKeyAcceptSsh.age
        );

        boot.initrd.secrets."/etc/tauthkey" = cfg.oauthKeyFile;

        boot.initrd.systemd.storePaths = [
          "${cfg.package}/bin/tailscaled"
          "${cfg.package}/bin/tailscale"
          "${pkgs.iproute2}/bin/ip"
          # needed for oauth keys
          "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        ];

        boot.initrd.systemd.services.tailscaled = {
          description = "Tailscaled for initrd";
          wantedBy = [ "initrd.target" ];
          path = [ pkgs.iproute2 ];
          after = [
            "network.target"
            "initrd-nixos-copy-secrets.service"
          ];

          # needed to get the service to start BEFORE the disks are unlocked
          unitConfig.DefaultDependencies = false;
          before = [ "shutdown.target" ];
          conflicts = [ "shutdown.target" ];

          serviceConfig = {
            Type = "notify";
            RuntimeDirectory = "tailscale";
            ExecStart = "${cfg.package}/bin/tailscaled --state=mem: --statedir=/run/tailscale --socket=/run/tailscale/tailscaled.sock";
            Restart = "on-failure";
          };
        };

        boot.initrd.systemd.services.tailscaled-autoconnect = {
          description = "Connect to Tailscale for initrd";
          wantedBy = [ "initrd.target" ];
          after = [
            "tailscaled.service"
            "network-online.target"
          ];
          wants = [ "network-online.target" ];
          requires = [ "tailscaled.service" ];

          # needed to get the service to start BEFORE the disks are unlocked
          unitConfig.DefaultDependencies = false;
          before = [ "shutdown.target" ];
          conflicts = [ "shutdown.target" ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            Restart = "on-failure";
            RestartSec = 5;
            # oauth keys require valid ssl certificates
            Environment = [ "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
          };
          script = ''
            ${cfg.package}/bin/tailscale --socket=/run/tailscale/tailscaled.sock up \
              --hostname=${config.networking.hostName}-initrd \
              --auth-key=file:/etc/tauthkey \
              --netfilter-mode=off \
              ${lib.escapeShellArgs cfg.extraUpFlags}
          '';
        };
      })
      (lib.mkIf (config.boot.initrd.network.enable && cfg.enable) {
        ### initrd secrets are deployed before agenix sets up keys. So the key needs to exist first, or the build will fail with a missing file error.
        ### So, on a system install use amReinstalling to disable the above actual deployment of the secret, while still deploying the key here.
        ### Then when you remove amReinstalling, initrd will see the secret deployed by the previous rebuild.
        age.secrets.tailscaleOAuthKeyAcceptSsh.file = (
          inputs.self + /secrets/tailscaleOAuthKeyAcceptSsh.age
        );
      })
    ];
}
