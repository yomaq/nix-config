{ config, lib, pkgs, ... }: {
  config = {
    homebrew = {
      casks = [
        "brave-browser"
      ];
    };
  };
}