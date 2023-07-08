{ inputs, ... }@flakeContext:
let
  homeModule = { config, lib, pkgs, ... }: {
    imports = [
      inputs.self.homeModules.default
    ];
    config = {
      manual = {
        manpages = {
          enable = false;
        };
      };
      programs = {
        tmux = {
          shell = "/etc/profiles/per-user/carln/bin/bash";
        };
      };
    };
  };
  nixosModule = { ... }: {
    home-manager.users.carln = homeModule;
  };
in
(
  (
    inputs.home-manager.lib.homeManagerConfiguration {
      modules = [
        homeModule
      ];
      pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
    }
  ) // { inherit nixosModule; }
)
