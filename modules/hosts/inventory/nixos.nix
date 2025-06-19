{
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [
    "${toString inputs.self}/inventory.nix"
  ];

  options = {
    inventory = {
      hosts = lib.mkOption {
        description = "Host inventory";
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              enable = lib.mkEnableOption "host" // {
                default = true;
              };
            };
          }
        );
        default = { };
      };
    };
    yomaq.hostName = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = ''
        way to access hostname that is OS agnostic
      '';
    };
  };

  config = {
    assertions = [
      # Verify all inventory hosts exist as nixosConfigurations
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
  };
}
