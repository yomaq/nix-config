{ config, lib, pkgs, inputs, ... }:
{
  imports =[
    # import custom modules
    inputs.self.nixosModules.yomaq
    inputs.self.nixosModules.pods
    # import users
    (inputs.self + /users/admin)
  ];
  config = {
    networking.hostName = "green";
    system.stateVersion = "23.05";
    networking.useDHCP = lib.mkDefault true;

    yomaq = {
      autoUpgrade.enable = true;
      primaryUser.users = [ "admin" ];
      tailscale = {
        enable = true;
        extraUpFlags = ["--ssh=true" "--reset=true" "--accept-dns=true" "--advertise-exit-node=true" ];
      };
      _1password.enable = true;
      # docker.enable = true;
      # pods.tailscale.enable = true;
      # pods.pihole.enable = true;
      # pods.nextcloud.enable = true;
    };
    environment.systemPackages = [
      # inputs.self.packages.x86_64-linux.traefik-test
      pkgs.yomaq.traefik-test
    ];
  };
}
