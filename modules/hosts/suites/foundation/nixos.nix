{
  config,
  lib,
  inputs,
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
        ssh.enable = true;
      };
    })
    {
      assertions = lib.mkIf cfg.enable [
        {
          assertion = cfg.enable -> lib.hasAttr config.networking.hostName config.inventory.hosts;
          message = "Error: Hostname '${config.networking.hostName}' not found in inventory.";
        }
        {
          assertion =
            let
              inventoryHosts = builtins.attrNames config.inventory.hosts;
              nixosHosts = builtins.attrNames inputs.self.nixosConfigurations;
              invalidHosts = lib.subtractLists nixosHosts inventoryHosts;
            in
            invalidHosts == [ ];
          message = "Error: The following hosts in inventory don't exist in nixosConfigurations: ${
            lib.concatStringsSep ", " (
              let
                inventoryHosts = builtins.attrNames config.inventory.hosts;
                nixosHosts = builtins.attrNames inputs.self.nixosConfigurations;
                invalidHosts = lib.subtractLists nixosHosts inventoryHosts;
              in
              invalidHosts
            )
          }";
        }
      ];
    }
  ];
}
