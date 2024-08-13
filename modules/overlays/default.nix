# This file defines overlays
{ inputs, ... }:

{
  ## When applied, the stable nixpkgs set (declared in the flake inputs) will
  ## be accessible through 'pkgs.stable'
  # nixpkgs-stable = final: _prev: {
  #   stable = import inputs.nixpkgs-stable {
  #     system = final.system;
  #     config.allowUnfree = true;
  #   };
  # };
  ## When applied, the unstable nixpkgs set (declared in the flake inputs) will
  ## be accessible through 'pkgs.unstable'
  pkgs-unstable = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
