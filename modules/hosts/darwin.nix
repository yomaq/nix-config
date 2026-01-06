{ lib, ... }:

{
  imports = lib.yomaq.importDir ./. {
    exclude = [ "nixos.nix" ];
    excludeExact = [ "darwin.nix" ];
  };
}
