{ config, pkgs, ... }:{
  programs.zsh.enable = true;
  environment.shells = with pkgs; [ zsh];
}