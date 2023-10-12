{ config, lib, pkgs, inputs, ... }:
{
  # I have to do this so I can import it into multiple modules, because if I import it directly to multiple modules... it breaks
  imports =
    [
      inputs.impermanence.nixosModules.impermanence
    ];
}