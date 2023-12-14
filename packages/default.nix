{ pkgs ? import <nixpkgs> { } }: rec {

  traefik-test = pkgs.callPackage ./traefik { };

}