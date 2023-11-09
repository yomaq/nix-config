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
    # directories = [
    #   { directory = "/run/agenix";}
    # ];
    files = [
      { file = "/etc/ssh/${hostName}"; }
    ];
  
  };
    age.identityPaths = [ "/etc/ssh/${hostName}" ];
    age.secretsDir = "/nix/persistent/run/agenix";
}