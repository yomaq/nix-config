{ inputs, config, lib, pkgs, ... }: {
  config = {
    home = {
      packages = [
        pkgs.trayscale
        pkgs.spotify
        pkgs.steam
        pkgs.moonlight-qt
        pkgs._1password
      ];
      stateVersion = "23.05";
    };
    programs = {
    };
  };
}
