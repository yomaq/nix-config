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
    age.identityPaths = [ "/nix/persistent/etc/ssh/${hostName}" ];
    # age.secretsDir = "/nix/agenix/secrets";
    # age.secretsMountPoint = "/nix/agenix/secret-generations";
}