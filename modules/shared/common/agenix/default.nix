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
    files = [
      { file = "/etc/ssh/${hostName}"; }
    ];
  };
    age.identityPaths = [ "/etc/ssh/${hostName}" ];
    age.secrets = {
      # user secrets
      carln.file = ./carln.age;
      # application secrets
      tailscaleKey.file = ./tailscaleKey.age;
      # generic secrets
      encrypt.file = ./tailscaleKey.age;
    };
}