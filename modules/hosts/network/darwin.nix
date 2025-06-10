{
  config,
  lib,
  ...
}:
let
  cfg = config.yomaq.network;
in
{
  config = lib.mkIf cfg.basics {
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
  };
}
