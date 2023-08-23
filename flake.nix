{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Nix-Darwin
    nix-darwin.url = "flake:nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Secret Encription
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    
  };

  outputs = { nixpkgs, home-manager, nix-darwin, agenix, ... }@inputs: 
    let
      flakeContext = {
        inherit inputs;
      };
    in
     {
      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        # FIXME replace with your hostname
        your-hostname = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; }; # Pass flake inputs to our config
          # > Our main nixos configuration file <
          modules = [ ./nixos/configuration.nix ];
        };
      };


      # Nix-darwin configuration entrypoint
      # Available through 'darwin-rebuild switch --flake .#your-hostname'
      darwinConfigurations = {
        midnight = nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; };
          system = "aarch64-darwin"; # "x86_64-darwin" if you're using a pre M1 mac
          # > Our main nix-darwin configuration file <
          modules = [ ./nix-darwin/midnight.nix ];
        };
      };


      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        "carln@midnight" = home-manager.lib.homeManagerConfiguration {
          system = "aarch64-darwin"; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
          # > Our main home-manager configuration file <
          modules = [ ./home-manager/carlnMidnight.nix ];
        };
      };

      # Modules for importing without referencing their file location:
      darwinModules = {
        brew = import ./nix-darwin/modules/brew_macos.nix flakeContext;
        yabai = import ./nix-darwin/modules/yabai.nix flakeContext;
      };
      homeModules = {
        installs = import ./home-manager/modules/installs.nix flakeContext;
      };



     };
}
