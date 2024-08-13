{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [ inputs.agenix.homeManagerModules.default ];
}
