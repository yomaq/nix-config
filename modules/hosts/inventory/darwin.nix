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
            freeformType = lib.types.attrs;
          }
        );
        default = { };
      };
    };
    yomaq.hostName = lib.mkOption {
      type = lib.types.str;
      default = config.networking.computerName;
      description = ''
        way to access hostname that is OS agnostic
      '';
    };
  };
}
