{ lib, ... }:

{
  imports = lib.yomaq.importDir ./. {
    exclude = [ "darwin.nix" ];
    excludeExact = [ "nixos.nix" ];
  };
}
