{ inputs, lib, config, pkgs, ... }: {
  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
    # fix for home manager bug
  manual.manpages.enable = false;
  # home manager overlays
  nixpkgs = {
    overlays = [ 
      inputs.self.overlays.nixpkgs-stable
      inputs.agenix.overlays.default
      inputs.nur.overlay
      ];
      # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };
  };
}