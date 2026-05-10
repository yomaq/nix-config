{ pkgs, ... }:

{
  layeredImage = {
    name = "ghcr.io/yomaq/nix-config";
    tag = "violet";
    fromImage = pkgs.dockerTools.pullImage {
      imageName = "ghcr.io/ublue-os/bluefin";
      imageDigest = "sha256:ec4325b7ee3325fcacc91d3ebfa68e1e43ac382c502618705784419e9e98b93e";
      hash = "sha256-iwWhY8BiB0yhHmGo05m17EV7LqCC8aDGuCLHxdH0gTU=";
      finalImageTag = "44";
    };
  };

  caliga.os = "fedora";
  caliga.core.enable = true;

  environment.systemPackages = [
    pkgs.cowsay
    pkgs._1password-gui
    pkgs._1password-cli
  ];

  users.users.carln = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
    initialPassword = "test";
  };

  services.bootc-update.enable = true;
  nix.enable = true;

  system.stateVersion = "25.11";
}
