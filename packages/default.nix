{ pkgs ? import <nixpkgs> { } }: rec {

  # made to try to use the tailscale tls cert with traefik, appears to properly install traefik, but it still wont work with tailscale. Leaving now for reference for other packages.
  traefik-test = pkgs.callPackage ./traefik { };

}