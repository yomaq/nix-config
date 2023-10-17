{ config, pkgs, ... }:

{
  nixpkgs.overlays = [
    inputs.agenix.overlays.default
  ];
  environment.systemPackages = with pkgs; [
    agenix
    vim
    git
  ];
}