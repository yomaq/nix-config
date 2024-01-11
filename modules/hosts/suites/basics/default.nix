{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.yomaq.suites.basics;
in
{
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
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
    };
    nixpkgs.overlays = [ inputs.agenix.overlays.default ];
    environment.systemPackages = with pkgs; [
      vim
      git
      agenix
    ];
  };
}