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
    just
  ];
  programs = {
    git = {
      enable = true;
      userEmail = "yomaq@bsjm.xyz";
      userName = "yomaq";
    };
  };
  yomaq = {
    suites.basic.enable = true;
    nixvim.enable = true;
  };
}
