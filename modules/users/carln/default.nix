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
        pkgs.vscode
        pkgs.tailscale
        pkgs.alacritty
        pkgs.vim
        pkgs.tmux
        pkgs.git
        pkgs.nixd
        pkgs.claude-code
        pkgs.zed-editor
      ];
      nixos = with pkgs; [
        pkgs.nextcloud-client
        pkgs.brave
        pkgs.steam
      ];
    };
    homebrew = {
      casks = [
        "moonlight"
        "rustdesk"
        "discord"
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
      ];
    };
  };
  home-manager.users."${USER}" = lib.mkIf (lib.elem USER listOfUsers) {
    yomaq = {
      suites.basic.enable = true;
    };
    programs = {
      git = {
        enable = true;
        settings = {
          user = {
            email = "yomaq@bsjm.xyz";
            name = "yomaq";
          };
        };
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
