{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.yomaq.homebrew;
in
{
  options.yomaq.homebrew = {
    enable  = mkOption {
      type = types.bool;
      default = false;
      description = ''
      '';
    };
  };
  config = mkIf cfg.enable {
  #Some programs don't have nix packages available, so making use of Homebrew is needed, sadly there is also no way of installing home brew through nix
    homebrew = {
      brewPrefix = "/opt/homebrew/bin";
      brews = [
        "mas"
      ];
      enable = true;
      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
        upgrade = true;
      };
    };
  };
}