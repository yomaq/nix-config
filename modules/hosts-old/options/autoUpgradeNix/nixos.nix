{ options, config, lib, pkgs, inputs, ... }:
# from https://github.com/Misterio77/nix-config/blob/main/hosts/common/global/auto-upgrade.nix

with lib;
let
  cfg = config.yomaq.autoUpgrade;
  # Only enable auto upgrade if current config came from a clean tree
  # This avoids accidental auto-upgrades when working locally.
  isClean = inputs.self ? rev;
in
{
  options.yomaq.autoUpgrade = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom autoUpgrade module
      '';
    };
  };

  config = mkIf cfg.enable {
    system.autoUpgrade = {
      enable = isClean;
      dates = "hourly";
      flags = [
        "--refresh"
      ];
      flake = github:yomaq/nix-config;
    };

    # Only run if current config (self) is older than the new one.
    systemd.services.nixos-upgrade = lib.mkIf config.system.autoUpgrade.enable {
      serviceConfig.ExecCondition = lib.getExe (
        pkgs.writeShellScriptBin "check-date" ''
          lastModified() {
            nix flake metadata "$1" --refresh --json | ${lib.getExe pkgs.jq} '.lastModified'
          }
          test "$(lastModified "${config.system.autoUpgrade.flake}")"  -gt "$(lastModified "self")"
        ''
      );
    };
  };
}