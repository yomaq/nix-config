{ config, pkgs, ... }:

{

  # Set default shell
  programs.zsh.enable = true;
  environment.shells = with pkgs; [ zsh];

}