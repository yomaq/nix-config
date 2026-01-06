{
  description = "nix config";

  inputs = {
    # Nixpkgs
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # Nix-Darwin
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # Secret encryption
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    # Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    # Impermanence
    impermanence.url = "github:nix-community/impermanence";
    # Disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    # nix index for comma
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    # microvms
    microvm.url = "github:astro/microvm.nix";
    microvm.inputs.nixpkgs.follows = "nixpkgs";
    # nixos on wsl
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
  };

  outputs =
    {
      nixpkgs,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib.extend (
        final: _prev: {
          yomaq = import ./lib { lib = final; };
        }
      );
    in
    {
      inherit lib;

      devShells = {
        x86_64-linux.default = import ./Utilities/devShell/default.nix {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config = {
              allowUnfree = true;
            };
          };
        };
        aarch64-darwin.default = import ./Utilities/devShell/default.nix {
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            config = {
              allowUnfree = true;
            };
          };
        };
      };

      nixosConfigurations =
        let
          mkSystem =
            path:
            nixpkgs.lib.nixosSystem {
              inherit lib;
              system = "x86_64-linux";
              specialArgs = { inherit inputs; };
              modules = [ path ];
            };
          # host machines
          hostConfigs = nixpkgs.lib.genAttrs (builtins.attrNames (builtins.readDir ./hosts/nixos)) (
            name: mkSystem ./hosts/nixos/${name}
          );
          # microvms
          microVMDir = ./modules/virtualization/microvms;
          allMicroVMs = builtins.readDir microVMDir;
          microVMConfigs = nixpkgs.lib.genAttrs (builtins.filter (
            name:
            allMicroVMs.${name} == "directory" && builtins.pathExists (microVMDir + "/${name}/microvm.nix")
          ) (builtins.attrNames allMicroVMs)) (name: mkSystem (microVMDir + "/${name}/microvm.nix"));
        in
        hostConfigs // microVMConfigs;

      darwinConfigurations =
        let
          mkHost =
            name:
            inputs.nix-darwin.lib.darwinSystem {
              inherit lib;
              specialArgs = { inherit inputs; };
              system = "aarch64-darwin";
              modules = [ ./hosts/darwin/${name} ];
            };
          myHosts = builtins.attrNames (builtins.readDir ./hosts/darwin);
        in
        nixpkgs.lib.genAttrs myHosts mkHost;

      overlays = import ./modules/overlays { inherit inputs; };

      nixosModules = {
        yomaq = import ./modules/hosts/nixos.nix;
        virtualization = import ./modules/virtualization;
      };

      darwinModules = {
        yomaq = import ./modules/hosts/darwin.nix;
      };

      homeManagerModules = {
        yomaq = import ./modules/home-manager;
      };

      users = {
        yomaq = import ./users;
      };
    };
}
