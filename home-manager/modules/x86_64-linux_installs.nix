{ inputs, config, lib, pkgs, ... }: {
  config = {
    home = {
      packages = [
        pkgs._1password-gui
        pkgs.trayscale
        pkgs.spotify
        pkgs.steam
        pkgs.sunshine
      ];
      stateVersion = "23.05";
    };
    programs = {
    };
  };
}
