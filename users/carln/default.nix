{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  USER = "carln";
in
{
  yomaq.users.users."${USER}" = {
    isRoot = true;
    hasNixosPassword = true;
    nixpkgs = {
      common = with pkgs; [
        pkgs.tailscale
        pkgs.discord
        pkgs.alacritty
        pkgs.vim
        pkgs.kubectl
        pkgs.nerdfonts
        pkgs.kubernetes-helm
        pkgs.git
      ];
      nixos = with pkgs; [
        pkgs.nextcloud-client
        pkgs.steam
        pkgs.brave
        pkgs.xwaylandvideobridge
      ];
    };
    homebrew = {
      casks = [
        "moonlight"
        "raycast"
        "arc"
        "linearmouse"
        "spotify"
        "nextcloud"
        "brave-browser"
        "zen-browser"
        "obsidian"
      ];
      taps = [ "pulumi/tap" ];
      brews = [
        "mas"
        "pulumi"
        "pulumi/tap/crd2pulumi"
        "pulumi/tap/kube2pulumi"
      ];
    };
  };
  home-manager.users."${USER}" = lib.mkIf (lib.elem USER config.yomaq.users.enableUsers) {
    yomaq = {
      suites.basic.enable = true;
      gnomeOptions.enable = true;
      vscode.enable = true;
      alacritty.enable = true;
    };
    programs = {
      git = {
        enable = true;
        userEmail = "yomaq@bsjm.xyz";
        userName = "yomaq";
      };
    };
    home.file.onePassword = {
      enable = true;
      target = ".config/1Password/ssh/agent.toml";
      text = ''
        [[ssh-keys]]
        vault = "ssh"
      '';
    };
  };
}
