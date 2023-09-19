{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports =
    [
       ./brew_macos.nix
       ./yabai.nix
    ];
}
