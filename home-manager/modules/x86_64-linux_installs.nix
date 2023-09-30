{ inputs, config, lib, pkgs, ... }: {
  config = {
    home = {
      packages = [
        pkgs.trayscale
        pkgs.spotify
        pkgs.steam
        pkgs.moonlight-qt
      ];
      stateVersion = "23.05";
    };
    programs = {
    };
  };
}
