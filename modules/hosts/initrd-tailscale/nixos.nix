{ config, lib, pkgs, inputs, ... }:

### pulled some lines from Andrew-d's comment here: https://github.com/NixOS/nixpkgs/pull/204249/files
### oauthkeys are currently not working because of trusted CA issues. Currently don't know how to fix for initrd.
### oauthkeys would be prefered because they don't need refreshed.
### authkeys expired every 3 months and will need to be manually updated.
### I have had weird results when trying to overwrite existing key files in initrd, often times only re-naming to a fresh file name appears to work.

with lib;
let
  cfg = config.yomaq.initrd-tailscale;
in
{
  options = {
    yomaq.initrd-tailscale = {
        enable = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Starts a Tailscale during initrd boot. It can be used to e.g.
          remotely accessing the SSH service controlled by
          {option}`boot.initrd.network.ssh` or other network services
          included. Service is killed when stage-1 boot is finished.
        '';
      };
      
      package = lib.mkPackageOptionMD pkgs "tailscale" {};

      authKeyFile = mkOption {
        type = types.nullOr types.path;
        default = "${config.age.secrets.tailscaleOAuthKeyAcceptSsh.path}";
        example = "/run/secrets/tailscale_key";
        description = lib.mdDoc ''
          A file containing the auth key.
        '';
      };

      extraUpFlags = mkOption {
        description = lib.mdDoc "Extra flags to pass to {command}`tailscale up`.";
        type = types.listOf types.str;
        default = [];
        example = ["--ssh"];
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
    mkMerge [ 
    (mkIf (config.boot.initrd.network.enable && !config.yomaq.disks.amReinstalling && cfg.enable) {

    boot.initrd.kernelModules = [ "tun" ];
    boot.initrd.availableKernelModules = [
      # "ip6_tables"
      # "ip6t_rpfilter"
      # "ip_tables"
      # "ipt_rpfilter"
      # "libcrc32c"
      # "nf_conntrack"
      # "nf_conntrack_netlink"
      # "nf_defrag_ipv4"
      # "nf_defrag_ipv6"
      # "nf_nat"
      # "nfnetlink"
      # "nf_reject_ipv4"
      # "nf_reject_ipv6"
      # "nf_tables"
      # "tun"
      # "x_tables"

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
      copy_bin_and_libs ${cfg.package}/bin/.tailscaled-wrapped
      copy_bin_and_libs ${cfg.package}/bin/.tailscale-wrapped
      copy_bin_and_libs ${pkgs.iproute}/bin/ip
      copy_bin_and_libs ${iptables-static}/bin/iptables
      copy_bin_and_libs ${iptables-static}/bin/ip6tables
      copy_bin_and_libs ${iptables-static}/bin/xtables-legacy-multi
      copy_bin_and_libs ${iptables-static}/bin/xtables-nft-multi
    '';

    age.secrets.tailscaleOAuthKeyAcceptSsh.file = (inputs.self + /secrets/tailscaleOAuthKeyAcceptSsh.age);

    boot.initrd.secrets."/etc/tauthkey" = cfg.authKeyFile;

    boot.initrd.network.postCommands = mkIf (!config.boot.initrd.systemd.enable) ''
      .tailscaled-wrapped --state=mem: &
      .tailscale-wrapped up --hostname=${config.networking.hostName}-initrd --auth-key 'file:/etc/tauthkey' ${escapeShellArgs cfg.extraUpFlags} &
    '';
    # oathkeys need dns and trusted CA's.
    # echo "nameserver 1.1.1.1" >> /etc/resolv.conf &

  #   boot.initrd.systemd.enable = true;
  #   boot.initrd.systemd.services.tailscaled = {
  #     wantedBy = [ "initrd.target" ];
  #     path = [ pkgs.kmod ];
  #     after = [ "network.target" "initrd-nixos-copy-secrets.service" ];
  #     serviceConfig.ExecStart = ".tailscaled-wrapped";
  #     serviceConfig.Type = "notify";
  #   };
  #   boot.initrd.systemd.services.tailscale = {
  #     wantedBy = [ "initrd.target" ];
  #     after = [ "tailscaled.service" ];
  #     serviceConfig.ExecStart = ".tailscale-wrapped up --auth-key 'file:/etc/authkey' ${escapeShellArgs cfg.extraUpFlags}";
  #     serviceConfig.Type = "notify";
  #   };
  })
  (mkIf (config.boot.initrd.network.enable && cfg.enable) {
    ### initrd secrets are deployed before agenix sets up keys. So the key needs to exist first, or the build will fail with a missing file error.
    ### So, on a system install use amReinstalling to disable the above actual deployment of the secret, while still deploying the key here.
    ## Then when you remove amReinstalling, initrd will see the secret deployed by the previous rebuild.
    age.secrets.tailscaleOAuthKeyAcceptSsh.file = (inputs.self + /secrets/tailscaleOAuthKeyAcceptSsh.age);
  })];
}