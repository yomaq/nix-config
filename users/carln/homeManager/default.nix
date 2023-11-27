{ inputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.self.homeManagerModules.yomaq
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
    pkgs.stable.talosctl
    pkgs.kubectl
    pkgs.nerdfonts
    pkgs.chezmoi
    pkgs.tmuxinator
    pkgs.kubernetes-helm
    pkgs.agenix
    pkgs.git
    pkgs.gh
  ] ++ (lib.optionals (pkgs.system != "aarch64-darwin") [
### nixos specific packages
    pkgs.trayscale
    pkgs.spotify
    pkgs.steam
    # pkgs.moonlight-qt
  ]);
  yomaq = {
    zsh.enable = true;
    vscode.enable = true;
    gnomeOptions.enable = true;
    firefox.enable = true;
  };
}
