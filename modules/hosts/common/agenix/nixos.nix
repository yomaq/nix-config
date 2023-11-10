{ config, lib, pkgs, inputs, ... }:
let
  inherit (config.networking) hostName;
in
{
  imports =
    [
      inputs.agenix.nixosModules.default
    ];
environment.persistence."${config.yomaq.impermanence.dontBackup}" = {
    hideMounts = true;
    files = [
      { file = "/etc/ssh/${hostName}"; }
    ];
  
  };
  age.identityPaths = [ 
    # with impermanence, on host reboot agenix tries to decript before /etc is created.
    # to fix we use the persistent location for the identityPaths
    "${config.yomaq.impermanence.dontBackup}/etc/ssh/${hostName}"
    "/etc/ssh/${hostName}"
  ];
}