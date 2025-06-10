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
        syncoid.enable = true;
        initrd-tailscale.enable = true;
        fwupd.enable = true;
        glances.enable = true;
        monitorServices.enable = true;
      };
    })
    (lib.mkIf (cfg.enable && 
               lib.hasAttr config.networking.hostName config.inventory.hosts) {
      # Use lib.optionalAttrs to avoid the attribute error
      yomaq = lib.attrByPath 
        ["${config.networking.hostName}"] 
        {} 
        config.inventory.hosts;
    })
    {
      # Keep your assertion, but it won't cause evaluation errors
      assertions = [
        {
          assertion = cfg.enable -> lib.hasAttr config.networking.hostName config.inventory.hosts;
          message = "Error: Hostname '${config.networking.hostName}' not found in inventory.";
        }
      ];
    }
  ];
}
