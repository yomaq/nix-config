{ inputs, ... }@flakeContext:
let
  homeModule = { config, lib, pkgs, ... }: {
    imports = [
      inputs.self.homeModules.default
    ];
    config = {
      home = {
        homeDirectory = /home/carln;
        username = "carln";
      };
      targets = {
        genericLinux = {
          enable = true;
        };
      };
    };
  };
  nixosModule = { ... }: {
    home-manager.users.carln86 = homeModule;
  };
in
(
  (
    inputs.home-manager.lib.homeManagerConfiguration {
      modules = [
        homeModule
      ];
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    }
  ) // { inherit nixosModule; }
)
