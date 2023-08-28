{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.sunshine;
in
{
  options.services.sunshine = {
    enable = mkEnableOption "sunshine";

    package = mkPackageOption pkgs "sunshine" { };
  };
  

  config = mkIf cfg.enable {

    systemd.user.services = {
      sunshine = {
        Unit.Description = "Sunshine is a Game stream host for Moonlight.";
        Service.ExecStart = "${cfg.package}/bin/sunshine";
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}