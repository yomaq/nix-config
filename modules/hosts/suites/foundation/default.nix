{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  cfg = config.yomaq.suites.foundation;
in
{
  options.yomaq.suites.foundation = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''basic configuration that should be set for all systems by default'';
    };
  };

  config = lib.mkIf cfg.enable {
    yomaq = {
      zsh.enable = true;
      agenix.enable = true;
      nixSettings.enable = true;
      tailscale.enable = true;
      network.basics = true;
    };
    nixpkgs.overlays = [ inputs.agenix.overlays.default ];
    environment.systemPackages = with pkgs; [
      vim
      git
      agenix
      nixos-rebuild
    ];
  };
}
