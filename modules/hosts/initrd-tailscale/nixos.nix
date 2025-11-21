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
        description = lib.mdDoc ''
          Starts Tailscale during initrd boot.
        '';
      };

      package = lib.mkPackageOption pkgs "tailscale" { };

      authKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = "${config.age.secrets.tailscaleOAuthKeyAcceptSsh.path}";
        example = "/run/secrets/tailscale_key";
        description = lib.mdDoc ''
          A file containing the auth key.
        '';
      };
      
      extraUpFlags = lib.mkOption {
        description = lib.mdDoc "Extra flags to pass to {command}`tailscale up`.";
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "--ssh" ];
      };
    };
  };
  config =
    let
      iptables-static = pkgs.iptables.overrideAttrs (old: {
        dontDisableStatic = true;
        configureFlags = (lib.remove "--enable-shared" old.configureFlags) ++ [
          "--enable-static"
          "--disable-shared"
        ];
      });
    in
    lib.mkMerge [
      (lib.mkIf (config.boot.initrd.network.enable && !config.yomaq.disks.amReinstalling && cfg.enable) {

        boot.initrd.kernelModules = [ "tun" ];
        boot.initrd.availableKernelModules = [
          "xt_mark"
          "nft_chain_nat"
          "nft_compat"
          "nft_compat"
          "xt_LOG"
          "xt_MASQUERADE"
          "xt_addrtype"
          "xt_comment"
          "xt_conntrack"
          "xt_multiport"
          "xt_pkttype"
          "xt_tcpudp"
        ];
        boot.initrd.extraUtilsCommands = ''
          copy_bin_and_libs ${pkgs.tailscale}/bin/.tailscaled-wrapped
          copy_bin_and_libs ${pkgs.iproute2}/bin/ip
          copy_bin_and_libs ${iptables-static}/bin/iptables
          copy_bin_and_libs ${iptables-static}/bin/ip6tables
          copy_bin_and_libs ${iptables-static}/bin/xtables-legacy-multi
          copy_bin_and_libs ${iptables-static}/bin/xtables-nft-multi
          ln -sf .tailscaled-wrapped $out/bin/tailscale
        '';
        age.secrets.tailscaleOAuthKeyAcceptSsh.file = (
          inputs.self + /secrets/tailscaleOAuthKeyAcceptSsh.age
        );

        boot.initrd.secrets."/etc/tauthkey" = cfg.authKeyFile;

        boot.initrd.network.postCommands = lib.mkIf (!config.boot.initrd.systemd.enable) ''
          .tailscaled-wrapped --state=mem: &
          tailscale up --hostname=${config.networking.hostName}-initrd --auth-key 'file:/etc/tauthkey' ${lib.escapeShellArgs cfg.extraUpFlags} &
        '';
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
