{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.yomaq.nixSettings;
in
{
  options.yomaq.nixSettings = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom nix settings
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nix = {
      # This will add each flake input as a registry
      # To make nix3 commands consistent with your flake
      registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

      # This will additionally add your inputs to the system's legacy channels
      # Making legacy nix commands consistent as well
      nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
      
      optimise.automatic = true;
      settings = {
        # Enable flakes and new 'nix' command
        experimental-features = "nix-command flakes";
        # Add community cache
        substituters = [
          "https://nix-community.cachix.org"
          "https://cache.nixos.org/"
          "https://devenv.cachix.org"
        ];
        trusted-public-keys = [
          # for nix-community cachix
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          # devenv
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        ];
      };
    };
    nixpkgs = {
      overlays = [
        inputs.self.overlays.pkgs-unstable
        inputs.agenix.overlays.default
      ];
      # Configure your nixpkgs instance
      config = {
        # Disable if you don't want unfree packages
        allowUnfree = true;
        # Workaround for https://github.com/nix-community/home-manager/issues/2942
        allowUnfreePredicate = (_: true);
      };
    };
  };
}
