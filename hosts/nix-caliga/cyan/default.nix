{ pkgs, ... }:

{
  layeredImage = {
    name = "ghcr.io/yomaq/nix-config";
    tag = "cyan";
    maxLayers = 125;
    fromImage = pkgs.dockerTools.pullImage {
      imageName = "ghcr.io/projectbluefin/dakota";
      imageDigest = "sha256:1876990f38722642c241e2a765022984e87f8df1ef29a05aa4bd5f63f30cb924";
      hash = "sha256-C/tbOfuR/QP09qqvf3IrxjAj/Wj0WJsZbAQ9S6x9lJo=";
      finalImageTag = "latest";
    };
  };

  environment.systemPackages = [
    pkgs.cowsay
    pkgs._1password-gui
    pkgs._1password-cli
  ];

  caliga.os = "gnomeOS";
  caliga.core.enable = true;

  users.users.carln = {
    isNormalUser = true;
    uid = 1007;
    initialPassword = "test";
    extraGroups = [ "wheel" ];
  };

  system.stateVersion = "25.11";
}
