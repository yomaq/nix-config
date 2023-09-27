{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports =
    [
       ./vscode.nix
    ];
}
