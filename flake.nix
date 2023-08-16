{
  description = "";
  inputs = {
    nixpkgs.url = "flake:nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "flake:nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "flake:home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    #Secret Encription
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      flakeContext = {
        inherit inputs;
      };
    in
    {
      darwinConfigurations = {
        midnight = import ./darwinConfigurations/midnight.nix flakeContext;
      };
      darwinModules = {
        default = import ./darwinModules/default.nix flakeContext;
        yabai = import ./darwinModules/yabai.nix flakeContext;
        tailscale = import ./darwinModules/tailscale.nix flakeContext;
      };
      homeConfigurations = {
        "carln@midnight" = import ./homeConfigurations/carln.nix flakeContext;
        carln = import ./homeConfigurations/carln86.nix flakeContext;
      };
      homeModules = {
        default = import ./homeModules/default.nix flakeContext;
      };
    };
}
