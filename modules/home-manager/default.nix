{ config, lib, pkgs, modulesPath, inputs, ... }:
{
  imports =
    [
      ./options
      ./common
    ];
}