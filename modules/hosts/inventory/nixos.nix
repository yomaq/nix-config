{ config, lib, inputs, ... }:
{
  imports = [ 
    # Assuming inventory.nix is at the root of your flake
    "${toString inputs.self}/inventory.nix"
  ];

  options.inventory = {
    hosts = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = {};
      description = "Inventory of nixos hosts and their 'yomaq' config. The inventory allows all hosts to be aware of the configuration of other hosts.";
    };
  };

  config = {
    assertions = [
      # Verify all inventory hosts exist as nixosConfigurations
      {
        assertion = let 
          inventoryHosts = builtins.attrNames config.inventory.hosts;
          nixosHosts = builtins.attrNames inputs.self.nixosConfigurations;
          invalidHosts = lib.subtractLists nixosHosts inventoryHosts;
        in invalidHosts == [];
        message = "Error: The following hosts in inventory don't exist in nixosConfigurations: ${
          lib.concatStringsSep ", " (
            let 
              inventoryHosts = builtins.attrNames config.inventory.hosts;
              nixosHosts = builtins.attrNames inputs.self.nixosConfigurations;
              invalidHosts = lib.subtractLists nixosHosts inventoryHosts;
            in invalidHosts
          )
        }";
      }
    ];
  };
}
