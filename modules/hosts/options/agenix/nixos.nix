{ config, lib, pkgs, inputs, ... }:
let
  inherit (config.networking) localHostName;
  cfg = config.yomaq.agenix;
in
{
  imports = [ inputs.agenix.nixosModules.default ];
  config = lib.mkIf cfg.enable {
      age.identityPaths = [ "/etc/ssh/${localHostName}" ];
  };
}