{ config, pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    git
  ];
}