{
  description = "nix config";
  inputs = {
    # Nixpkgs
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable"; 
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # Nix-Darwin
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # Secret Encription
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    # Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    # Nix User Repository
    nur.url = "github:nix-community/NUR";
    # Impermanance
    impermanence.url = "github:nix-community/impermanence";
    # Disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, home-manager, nix-darwin, agenix, ... }@inputs: 
    let
      inherit (self) outputs;
      forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
    in
  {
    inherit lib;
    packages = forEachSystem (pkgs: import ./packages { inherit inputs; });
    overlays = import ./modules/overlays {inherit inputs;};
### Host outputs
    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild switch --flake .#your-hostname'
    nixosConfigurations = {
      blue = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; }; 
        modules = [ ./hosts/blue ];
      };
      green = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; }; 
        modules = [ ./hosts/green ];
      };
      azure = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; }; 
        modules = [ ./hosts/azure ];
      };
    };
    # Nix-darwin configuration entrypoint
    # Available through 'darwin-rebuild switch --flake .#your-hostname'
    darwinConfigurations = {
      midnight = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        system = "aarch64-darwin"; 
        modules = [ ./hosts/midnight ];
      };
    };
    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#your-username@your-hostname'
    homeConfigurations = {
      "carln@hostname" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {inherit inputs;};
        modules = [./users/carln/homeManager];
      };
    };
### Module outputs
    nixosModules = {
      yomaq = import ./modules/hosts/nixos.nix;
      # custom container modules
      pods = import ./modules/containers;
    };
    darwinModules = {
      yomaq = import ./modules/hosts/darwin.nix;
    };
    homeManagerModules = {
      yomaq = import ./modules/home-manager;
    };
  };
}
