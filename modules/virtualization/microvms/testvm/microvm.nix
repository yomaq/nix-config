{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
let
  vmName = "testvm";
in
{
  imports = [
    ../microvm.nix
  ];
  config = {
    networking.hostName = "${vmName}";

  };
}
