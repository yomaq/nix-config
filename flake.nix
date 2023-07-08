{
  description = "";
  inputs = {
    nixpkgs.url = "flake:nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "flake:nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "flake:home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs:
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
      };
      homeConfigurations = {
        carln = import ./homeConfigurations/carln.nix flakeContext;
        carln86 = import ./homeConfigurations/carln86.nix flakeContext;
      };
      homeModules = {
        default = import ./homeModules/default.nix flakeContext;
      };
    };
}
