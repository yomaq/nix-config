{ pkgs, ... }:

{
  layeredImage = {
    name = "ghcr.io/yomaq/nix-config";
    tag = "violet";
    fromImage = pkgs.dockerTools.pullImage {
      imageName = "ghcr.io/ublue-os/aurora";
      imageDigest = "sha256:562db764497cabb0b6a618776429be072d22525190b3b3bffd3030b67f4c5874";
      hash = "sha256-FgQY0+YZGlB6fHtyhFjlzsE337B2E97Y0er/JaS9H0E=";
      finalImageName = "ghcr.io/ublue-os/aurora";
      finalImageTag = "stable";
    };
    config.Labels = {
      "containers.bootc" = "1";
      "ostree.bootable" = "true";
      "org.opencontainers.image.source" = "https://github.com/yomaq/nix-config";
    };
  };

  environment.systemPackages = [
    pkgs.cowsay
    pkgs._1password-gui
    pkgs._1password-cli
  ];

  users.users.carln = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "plugdev" ];
    initialPassword = "test";
  };

  services.bootc-update.enable = true;
  nix.enable = true;

  system.stateVersion = "25.11";
}
