{ config, lib, pkgs, inputs, ... }:
let
  inherit (config.networking) hostName;
in
{
  imports =
    [
      inputs.agenix.nixosModules.default
    ];
  environment.persistence."/nix/persistent" = {
    hideMounts = true;
    directories = [
      # { directory = "/run/agenix.d";}
      # { directory = "/run/agenix";}
    ];
    files = [
      { file = "/etc/ssh/${hostName}"; }
    ];
  
  };
    age.identityPaths = [ 
      # with impermanence, on host reboot agenix tries to decript before /etc is created.
      # to fix we use the persistent location for the identityPaths
      "/nix/persistent/etc/ssh/${hostName}"
      "/etc/ssh/${hostName}"
      ];
    # age.secretsDir = "/nix/agenix/secrets";
    # age.secretsMountPoint = "/nix/agenix/secret-generations";
}