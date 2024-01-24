{ inputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.self.homeManagerModules.yomaq
    ];
# https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
  home.packages = with pkgs; [
    vim
    gh
    agenix
    tailscale
  ];
  programs = {
    git = {
      enable = true;
      userEmail = "112864332+yomaq@users.noreply.github.com";
      userName = "yomaq";
    };
  };
  yomaq = {
    suites.basic.enable = true;
  };
}
