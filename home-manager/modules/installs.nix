{ inputs, config, lib, pkgs, outputs, ... }: {
  config = {
  nixpkgs.overlays = [ inputs.self.overlays.nixpkgs-stable ];
    home = {
      packages = [
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
      ] ++ mkIf (cfg.enable && pkgs.system != "aarch64-darwin") [
    ### nixos specific packages
        pkgs.trayscale
        pkgs.spotify
        pkgs.steam
        pkgs.moonlight-qt
      ];
      stateVersion = "23.05";
    };
  };
}
