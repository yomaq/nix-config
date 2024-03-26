{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.yomaq.suites.basics;
in
{
  imports = [
  ];
  options.yomaq.suites.basics = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
      '';
    };
  };

  config = mkIf cfg.enable {
    yomaq = {
      zsh.enable =true;
      glances.enable = true;
    };
    nixpkgs.overlays = [ inputs.agenix.overlays.default ];
    environment.systemPackages = with pkgs; [
      vim
      git
      agenix
      just
      nixos-rebuild
    ];
  };
}