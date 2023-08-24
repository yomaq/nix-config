{ inputs, ... }@flakeContext:
let
  darwinModule = { config, lib, pkgs, ... }: {
    imports = [
      inputs.home-manager.darwinModules.home-manager
      inputs.self.homeConfigurations."carln@midnight".nixosModule
      inputs.self.darwinModules.default
      inputs.self.darwinModules.yabai
      inputs.self.darwinModules.tailscale
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      }
    ];
#Rename the Comptuer in every location that macs keep names.
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