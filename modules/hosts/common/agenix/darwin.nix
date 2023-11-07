{ config, lib, pkgs, inputs, ... }:
let
  inherit (config.networking) localHostName;
in
{
  imports =
    [
      inputs.agenix.darwinModules.default
    ];
    age.identityPaths = [ "/etc/ssh/${hostName}" ];
}