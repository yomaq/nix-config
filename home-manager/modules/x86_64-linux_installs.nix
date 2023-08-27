{ inputs, config, lib, pkgs, ... }: {
  config = {
    home = {
      packages = [
        pkgs._1password-gui
        pkgs.trayscale
        pkgs.spotify
      ];
      stateVersion = "23.05";
    };
    programs = {
    };
  };
}
