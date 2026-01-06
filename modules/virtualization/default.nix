{ lib, ... }:

{
  imports = lib.yomaq.importDir ./. {
    exclude = [
      "microvm.nix"
      "containers/old/"
    ];
  };
}
