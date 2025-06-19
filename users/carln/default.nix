{
  config,
  lib,
  pkgs,
  ...
}:
let
  USER = "carln";
  listOfUsers = config.inventory.hosts."${config.networking.hostName}".users.enableUsers;
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
        pkgs.kubernetes-helm
        pkgs.git
      ];
      nixos = with pkgs; [
        pkgs.nextcloud-client
        pkgs.steam
        pkgs.brave
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
        "zen"
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
  home-manager.users."${USER}" = lib.mkIf (lib.elem USER listOfUsers) {
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
