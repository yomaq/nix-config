{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
# base around https://github.com/Misterio77/nix-config/blob/main/hosts/common/global/auto-upgrade.nix

let
  cfg = config.yomaq.autoUpgrade;
  # Only enable auto upgrade if current config came from a clean tree
  # This avoids accidental auto-upgrades when working locally.
  inherit (config.networking) hostName;
  isClean = inputs.self ? rev;
in
{
  options.yomaq.autoUpgrade = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom autoUpgrade module
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    system.autoUpgrade = {
      enable = isClean;
      dates = "hourly";
      flags = [ "--refresh" ];
      flake = "github:yomaq/nix-config";
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
      onFailure = [ "nixos-upgrade-fail.service" ];
      onSuccess = [ "nixos-upgrade-success.service" ];
    };
    systemd.services.nixos-upgrade-fail = lib.mkIf config.system.autoUpgrade.enable {
      script = ''${lib.getExe pkgs.curl} -H "t: NixOS Flake host rebuild failure" ${config.yomaq.ntfy.defaultPriority} -d "${hostName} failed to rebuild" ${config.yomaq.ntfy.ntfyUrl}${config.yomaq.ntfy.defaultTopic}'';
      #${lib.getExe pkgs.curl} -X POST ${config.yomaq.gatus.url}/api/v1/endpoints/Nixos-Host-Auto-Rebuilds_${hostName}/external?success=true -H "Authorization: Bearer nixos"

    };
    systemd.services.nixos-upgrade-success = lib.mkIf config.system.autoUpgrade.enable {
      script = ''${lib.getExe pkgs.curl} -fsS -m 10 --retry 5 ${
        config.yomaq.healthcheckUrl.nixos-upgrade."${hostName}"
      }'';
      # ${lib.getExe pkgs.curl} -X POST ${config.yomaq.gatus.url}/api/v1/endpoints/Nixos-Host-Auto-Rebuilds_${hostName}/external?success=false -H "Authorization: Bearer nixos"
    };

    yomaq.monitorServices.services.nixos-upgrade.priority = "high"; 

    ### not working, need to test more
    # yomaq.gatus.externalEndpoints = [{
    #   name = "${hostName}";
    #   group = "Nixos Host Auto Rebuilds";
    #   token = "nixos";
    #   url = config.yomaq.gatus.url;
    #   conditions = [
    #     "[CONNECTED] == true"
    #   ];
    #   alerts = [
    #     {
    #       type = "ntfy";
    #       failureThreshold = 1;
    #       description = "${hostName} rebuild failed";
    #     }
    #   ];
    # }];
  };
}
