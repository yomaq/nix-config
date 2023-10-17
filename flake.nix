{
  description = "nix config";
  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; 
    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # Nix-Darwin
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # Secret Encription
    agenix.url = "github:yomaq/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    # Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    # Nix User Repository
    nur.url = github:nix-community/NUR;
    # Impermanance
    impermanence.url = "github:nix-community/impermanence";
    # Disko
    disko.url = "https://flakehub.com/f/nix-community/disko/1.1.0.tar.gz";
  };
  outputs = { nixpkgs, home-manager, nix-darwin, agenix, ... }@inputs: 
  {

### Host outputs

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild switch --flake .#your-hostname'
    nixosConfigurations = {
      blue = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; }; 
        modules = [ ./nixos/hosts/blue ];
      };
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; }; 
        modules = [ ./nixos/hosts/nixos-test/nixostest.nix ];
      };
      nixos2 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; }; 
        modules = [ ./nixos/hosts/nixos2 ];
      };
    };
    # Nix-darwin configuration entrypoint
    # Available through 'darwin-rebuild switch --flake .#your-hostname'
    darwinConfigurations = {
      midnight = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        system = "aarch64-darwin"; 
        modules = [ ./nix-darwin/hosts/midnight.nix ];
      };
    };
### Module outputs
    sharedModules = { # modules that are used in both nixOS and nix-Darwin
      common = import ./modules/shared/common;
      options = import ./modules/shared/options;
    };
    nixosModules = {
      common = import ./modules/nixos/common;
      options = import ./modules/nixos/options;
    };
    darwinModules = {
      common = import ./modules/nix-darwin/common;
      options = import ./modules/nix-darwin/options;
    };
    homeManagerModules = {
      common = import ./modules/home-manager/common;
      options = import ./modules/home-manager/options;
    };
  };
}
