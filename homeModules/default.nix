{ inputs, ... }@flakeContext:
{ config, lib, pkgs, ... }: {
  config = {
    home = {
      packages = [
        pkgs.discord
        pkgs.vscode
        pkgs.bash
        pkgs.tmux
        pkgs.vim
        pkgs.talosctl
        pkgs.kubectl
      ];
      stateVersion = "23.11";
    };
    nixpkgs = {
      config = {
        allowUnfree = true;
      };
    };
    programs = {
      bash = {
        enable = true;
        enableCompletion = true;
      };
      tmux = {
        enable = true;
        mouse = true;
        tmuxinator = {
          enable = true;
        };
      };
    };
  };
}
