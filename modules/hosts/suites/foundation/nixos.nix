{
  config,
  lib,
  ...
}:
let
  cfg = config.yomaq.suites.foundation;
in
{
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      yomaq = {
        autoUpgrade.enable = true;
        initrd-tailscale.enable = true;
        fwupd.enable = true;
        glances.enable = true;
        monitorServices.enable = true;
      };
    })
    (lib.mkIf (cfg.enable && lib.hasAttr config.networking.hostName config.inventory.hosts) {
      # temporary measure while I move to using the inventory
      yomaq = lib.attrByPath [ "${config.networking.hostName}" ] { } config.inventory.hosts;
    })
    {
      assertions = [
        {
          assertion = cfg.enable -> lib.hasAttr config.networking.hostName config.inventory.hosts;
          message = "Error: Hostname '${config.networking.hostName}' not found in inventory.";
        }
      ];
    }
  ];
}
