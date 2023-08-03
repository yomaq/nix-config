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
        pkgs.oh-my-posh
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
      bash = {
        enable = true;
        enableCompletion = true;
        initExtra = "[ -f $HOME/.bashrc2 ] && . $HOME/.bashrc2";
      };
    };
  };
}
