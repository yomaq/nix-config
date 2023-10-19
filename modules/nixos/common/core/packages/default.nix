{ config, pkgs, inputs, ... }:

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