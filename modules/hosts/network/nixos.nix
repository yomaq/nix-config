{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.yomaq.network;
in
{

  config = lib.mkMerge [
    (lib.mkIf cfg.basics {
      networking.networkmanager.enable = true;

      networking.firewall = {
        enable = true;
        allowedTCPPorts = lib.mkForce [];
        allowedUDPPorts = lib.mkForce [];
        allowPing = false;
      };

      # Use networkd instead of the pile of shell scripts
      networking.useNetworkd = lib.mkDefault true;
      networking.useDHCP = lib.mkDefault false;

      # The notion of "online" is a broken concept
      # https://github.com/systemd/systemd/blob/e1b45a756f71deac8c1aa9a008bd0dab47f64777/NEWS#L13
      systemd.services.NetworkManager-wait-online.enable = false;
      systemd.network.wait-online.enable = false;

    })
    (lib.mkIf cfg.useBr0 {
      systemd.network = {
        netdevs = {
          "20-br0" = {
            netdevConfig = {
              Kind = "bridge";
              Name = "br0";
            };
          };
        };
        networks = {
          "30-${cfg.physicalInterfaceName}" = {
            matchConfig.Name = [
              "${cfg.physicalInterfaceName}"
              "vm-*"
            ];
            networkConfig.Bridge = "br0";
            linkConfig.RequiredForOnline = "enslaved";
          };
          "40-br0" = {
            matchConfig.Name = "br0";
            networkConfig.DHCP = "ipv4";
            linkConfig.RequiredForOnline = "carrier";
          };
        };
      };
    })
  ];
}
