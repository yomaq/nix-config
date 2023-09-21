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
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    # Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    # Nix User Repository
    nur.url = github:nix-community/NUR;
    # Impermanance
    impermanence.url = "github:nix-community/impermanence";
    # Disko
    disko.url = "https://flakehub.com/f/nix-community/disko/1.1.0.tar.gz"
  };
  outputs = { nixpkgs, home-manager, nix-darwin, agenix, ... }@inputs: 
  {
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
  };
}
