{ lib }:

{
  importDir = import ./importDir.nix { inherit lib; };
}
