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
            # macos does not import all modules where nixos specific inventory options are configured, so darwin accepts anything under inventory.hosts
            freeformType = lib.types.attrs;
          }
        );
      };
    };
  };
}
