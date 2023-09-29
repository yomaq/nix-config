{ config, lib, pkgs, inputs, ... }:
{
  imports =
    [
      inputs.agenix.nixosModules.default
    ];
}