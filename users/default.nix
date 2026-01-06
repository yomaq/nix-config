{ lib, ... }:

{
  imports = lib.yomaq.importDir ./. { pattern = "default.nix"; };
}
