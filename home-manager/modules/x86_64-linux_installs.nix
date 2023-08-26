{ inputs, ... }@flakeContext:
{ config, lib, pkgs, ... }: {
  config = {
    home = {
      packages = [
        pkgs.moonlight-qt
        pkgs._1password-gui
        pkgs.trayscale
      ];
      stateVersion = "23.05";
    };
    programs = {
    };
  };
}
