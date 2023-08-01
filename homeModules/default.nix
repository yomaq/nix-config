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
        pkgs.starship
        pkgs.nerdfonts
        pkgs.chezmoi
        pkgs._1password
        pkgs.tmuxinator
      ];
      stateVersion = "23.11";
    };
    nixpkgs = {
      config = {
        allowUnfree = true;
      };
    };
    programs = {
    };
  };
}
