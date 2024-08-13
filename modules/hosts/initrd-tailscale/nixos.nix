{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

### pulled some lines from Andrew-d's comment here: https://github.com/NixOS/nixpkgs/pull/204249/files
### oauthkeys are currently not working because of trusted CA issues. Currently don't know how to fix for initrd.
### oauthkeys would be prefered because they don't need refreshed.
### authkeys expired every 3 months and will need to be manually updated.

### https://github.com/NixOS/nixpkgs/pull/306532 Made this more complicated, as it removed tailscale-wrapped.
### Made an overlay to undo it and add tailscale-wrapped back.

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
          Starts Tailscale during initrd boot. It can be used to
          remotely accessing the SSH service controlled by
          {option}`boot.initrd.network.ssh` or other network services
          included. Service is killed when stage-1 boot is finished.
        '';
      };

      package = lib.mkPackageOptionMD pkgs "tailscale" { };

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

      # have to undo https://github.com/NixOS/nixpkgs/pull/306532
      TailscaleWrappedOverlay = self: super: {
        tailscale-wrapped = super.tailscale.overrideAttrs (oldAttrs: {
          subPackages = oldAttrs.subPackages ++ [ "cmd/tailscale" ];
          postInstall = lib.optionalString super.stdenv.isLinux ''
            wrapProgram $out/bin/tailscaled --prefix PATH : ${
              lib.makeBinPath [
                super.iproute2
                super.iptables
                super.getent
                super.shadow
              ]
            }
            wrapProgram $out/bin/tailscale --suffix PATH : ${lib.makeBinPath [ super.procps ]}
          '';
        });
      };

    in
    lib.mkMerge [
      (lib.mkIf (config.boot.initrd.network.enable && !config.yomaq.disks.amReinstalling && cfg.enable) {

        nixpkgs.overlays = [ TailscaleWrappedOverlay ];

        yomaq.initrd-tailscale.package = pkgs.tailscale-wrapped;

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
          copy_bin_and_libs ${cfg.package}/bin/.tailscaled-wrapped
          copy_bin_and_libs ${cfg.package}/bin/.tailscale-wrapped
          copy_bin_and_libs ${pkgs.iproute}/bin/ip
          copy_bin_and_libs ${iptables-static}/bin/iptables
          copy_bin_and_libs ${iptables-static}/bin/ip6tables
          copy_bin_and_libs ${iptables-static}/bin/xtables-legacy-multi
          copy_bin_and_libs ${iptables-static}/bin/xtables-nft-multi
        '';

        age.secrets.tailscaleOAuthKeyAcceptSsh.file = (
          inputs.self + /secrets/tailscaleOAuthKeyAcceptSsh.age
        );

        boot.initrd.secrets."/etc/tauthkey" = cfg.authKeyFile;

        boot.initrd.network.postCommands = lib.mkIf (!config.boot.initrd.systemd.enable) ''
          .tailscaled-wrapped --state=mem: &
          .tailscale-wrapped up --hostname=${config.networking.hostName}-initrd --auth-key 'file:/etc/tauthkey' ${lib.escapeShellArgs cfg.extraUpFlags} &
        '';

      })
      (lib.mkIf (config.boot.initrd.network.enable && cfg.enable) {
        ### initrd secrets are deployed before agenix sets up keys. So the key needs to exist first, or the build will fail with a missing file error.
        ### So, on a system install use amReinstalling to disable the above actual deployment of the secret, while still deploying the key here.
        ## Then when you remove amReinstalling, initrd will see the secret deployed by the previous rebuild.
        age.secrets.tailscaleOAuthKeyAcceptSsh.file = (
          inputs.self + /secrets/tailscaleOAuthKeyAcceptSsh.age
        );
      })
    ];

  # ### for systemd networking. the old script based initrd network is slowly being phased out
  # ### not tested yet, just starting to prep what I expect is needed.

  # boot.initrd.systemd.storePaths = [
  #   "${cfg.package}/bin/.tailscaled-wrapped"
  #   "${cfg.package}/bin/.tailscale-wrapped"
  #   "${pkgs.iproute}/bin/ip"
  #   "${iptables-static}/bin/iptables"
  #   "${iptables-static}/bin/ip6tables"
  #   "${iptables-static}/bin/xtables-legacy-multi"
  #   "${iptables-static}/bin/xtables-nft-multi"
  # ];
  # boot.initrd.systemd.services.tailscaled = {
  #   wantedBy = [ "initrd.target" ];
  #   path = [ pkgs.iproute iptables-static ];
  #   after = [ "network.target" "initrd-nixos-copy-secrets.service" ];
  #   serviceConfig.ExecStart = "${cfg.package}/bin/.tailscaled-wrapped --state=mem:";
  #   serviceConfig.Type = "notify";
  # };
  # boot.initrd.systemd.services.tailscaled = {
  #   wantedBy = [ "initrd.target" ];
  #   path = [ pkgs.iproute iptables-static ];
  #   after = [ "network.target" "initrd-nixos-copy-secrets.service" "tailscaled" ];
  #   serviceConfig.ExecStart = "${cfg.package}/bin/.tailscale-wrapped up --hostname=${config.networking.hostName}-initrd --auth-key 'file:/etc/tauthkey' ${escapeShellArgs cfg.extraUpFlags}";
  #   serviceConfig.Type = "notify";
  # };
}
