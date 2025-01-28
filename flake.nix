{
  description = "nix config";
  inputs = {
    # Nixpkgs
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # Nix-Darwin
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-24.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # Secret encryption
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    # Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    # Impermanance
    impermanence.url = "github:nix-community/impermanence";
    # Disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    # nix index for comma
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    # nixos generators
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
    # devenv
    devenv.url = "github:cachix/devenv";
    # flake.parts
    flake-parts.url = "github:hercules-ci/flake-parts";
    # microvms
    microvm.url = "github:astro/microvm.nix";
    microvm.inputs.nixpkgs.follows = "nixpkgs";
    # nixos on wsl
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    # lix
    lix.url = "https://git.lix.systems/lix-project/nixos-module/archive/2.92.0.tar.gz";
    lix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      nixos-generators,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        # systems for which you want to build the `perSystem` attributes
        "x86_64-linux"
        "aarch64-darwin"
      ];
      imports = [ inputs.devenv.flakeModule ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          # flake's own devenv
          devenv.shells.default = {
            imports = [ ./Utilities/devenv/default.nix ];
          };
        };
      # non-flake.parts outputs
      flake = {
        overlays = import ./modules/overlays { inherit inputs; };
        ### Host outputs
        # NixOS configuration entrypoint
        # Available through 'nixos-rebuild switch --flake .#your-hostname'
        nixosConfigurations = {
          blue = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit inputs;
            };
            modules = [ ./hosts/blue ];
          };
          azure = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit inputs;
            };
            modules = [ ./hosts/azure ];
          };
          carob = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit inputs;
            };
            modules = [ ./hosts/carob ];
          };
          teal = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit inputs;
            };
            modules = [ ./hosts/teal ];
          };
          smalt = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit inputs;
            };
            modules = [ ./hosts/smalt ];
          };
          green = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; }; 
            modules = [ ./hosts/green ];
          };
          pearl = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit inputs;
            };
            modules = [ ./hosts/pearl ];
          };
          # wsl = nixpkgs.lib.nixosSystem {
          #   system = "x86_64-linux";
          #   specialArgs = {
          #     inherit inputs;
          #   };
          #   modules = [ ./hosts/wsl ];
          # };
        };
        # Nix-darwin configuration entrypoint
        # Available through 'darwin-rebuild switch --flake .#your-hostname'
        darwinConfigurations = {
          midnight = nix-darwin.lib.darwinSystem {
            specialArgs = {
              inherit inputs;
            };
            system = "aarch64-darwin";
            modules = [ ./hosts/midnight ];
          };
        };
        # Standalone home-manager configuration entrypoint
        # Available through 'home-manager --flake .#your-username@your-hostname'
        homeConfigurations = {
          "carln@hostname" = home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
            extraSpecialArgs = {
              inherit inputs;
            };
            modules = [ ./users/carln/homeManager ];
          };
        };
        # Nixos-generators configuration entrypoints
        # Available through 'nix build .#your-hostname'
        packages.x86_64-linux = {
          #### requires --impure, breaks `nix flake check`
          # install-iso = nixos-generators.nixosGenerate {
          #   system = "x86_64-linux";
          #   format = "install-iso";
          #   specialArgs = { inherit inputs; };
          #   modules = [ ./hosts/install-iso ];
          # };
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
    };
}
