{ inputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.self.homeManagerModules.yomaq
    ./dotfiles
    ];
  home.stateVersion = "23.05";
  home.packages = [
### nixos + darwin packages
    pkgs.tailscale
    pkgs.discord
  ] ++ (lib.optionals (pkgs.system != "aarch64-darwin") [
### nixos specific packages
    pkgs.trayscale
    pkgs.steam
    pkgs.brave
  ]);
  programs = {};
  yomaq = {
    suites.basic.enable = true;
    gnomeOptions.enable = true;
    vscode.enable = true;
    alacritty.enable = true;
  };
}
