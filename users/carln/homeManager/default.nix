{ inputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.self.homeManagerModules.yomaq
    # inputs.nix-index-database.hmModules.nix-index
    ./dotfiles
    ];
# https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
  home.packages = [
### nixos + darwin packages
    pkgs.tailscale
    pkgs.discord
    pkgs.vscode
    pkgs.alacritty
    pkgs.vim
    pkgs.talosctl
    pkgs.kubectl
    pkgs.nerdfonts
    pkgs.chezmoi
    pkgs.tmuxinator
    pkgs.kubernetes-helm
    # pkgs.agenix
    pkgs.git
    pkgs.gh
  ] ++ (lib.optionals (pkgs.system != "aarch64-darwin") [
### nixos specific packages
    pkgs.trayscale
    #pkgs.spotify
    pkgs.steam
    pkgs.brave
    # pkgs.obsidian
  ]);
  programs = {
    # nix-index-database.comma.enable = true;
    git = {
      enable = true;
      userEmail = "112864332+yomaq@users.noreply.github.com";
      userName = "yomaq";
    };
  };
  yomaq = {
    zsh.enable = true;
    vscode.enable = true;
    gnomeOptions.enable = true;
  };
}
