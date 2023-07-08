{ inputs, ... }@flakeContext:
let
  darwinModule = { config, lib, pkgs, ... }: {
    imports = [
      inputs.home-manager.darwinModules.home-manager
      inputs.self.darwinModules.default
      inputs.self.homeConfigurations.carln.nixosModule
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      }
    ];
    config = {
      networking = {
        computerName = "midnight";
        localHostName = "midnight";
      };
      system = {
        defaults = {
          smb = {
            NetBIOSName = "midnight";
            ServerDescription = "midnight";
          };
        };
      };
    };
  };
in
inputs.nix-darwin.lib.darwinSystem {
  modules = [
    darwinModule
  ];
  system = "aarch64-darwin";
}
