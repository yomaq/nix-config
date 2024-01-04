{ config, lib, pkgs, ... }: {
#Network settings, plan to move these to their own module once I get wireguard setup
  networking = {
    knownNetworkServices = [
      ''
        [
          "USB 10/100/1000 LAN"
          "Thunderbolt Bridge"
          "Wi-Fi"
        ]
      ''
    ];
  };
}