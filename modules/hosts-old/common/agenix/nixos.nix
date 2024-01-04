{ config, lib, pkgs, inputs, ... }:
let
  inherit (config.networking) hostName;
in
{
  imports =
    [
      inputs.agenix.nixosModules.default
    ];
  age.identityPaths = [ 
    "/etc/ssh/${hostName}"
  ];
}