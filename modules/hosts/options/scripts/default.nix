{ options, config, lib, pkgs, inputs, ... }:
with lib;
let
  cfg = config.yomaq.scripts;
in
{
  options.yomaq.scripts = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        install custom scripts
      '';
    };
  };


 config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      (import ./initrdunlock.sh {inherit pkgs;})
    ];
 };
}