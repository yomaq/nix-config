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

      # pulled from https://github.com/nix-community/srvos/blob/main/nixos/common/networking.nix

      # Allow PMTU / DHCP
      networking.firewall.allowPing = true;

      # Keep dmesg/journalctl -k output readable by NOT logging
      # each refused connection on the open internet.
      networking.firewall.logRefusedConnections = lib.mkDefault false;

      # Use networkd instead of the pile of shell scripts
      networking.useNetworkd = lib.mkDefault true;
      networking.useDHCP = lib.mkDefault false;

      # The notion of "online" is a broken concept
      # https://github.com/systemd/systemd/blob/e1b45a756f71deac8c1aa9a008bd0dab47f64777/NEWS#L13
      systemd.services.NetworkManager-wait-online.enable = false;
      systemd.network.wait-online.enable = false;

      # # FIXME: Maybe upstream?
      # # Do not take down the network for too long when upgrading,
      # # This also prevents failures of services that are restarted instead of stopped.
      # # It will use `systemctl restart` rather than stopping it with `systemctl stop`
      # # followed by a delayed `systemctl start`.
      # systemd.services.systemd-networkd.stopIfChanged = false;
      # # Services that are only restarted might be not able to resolve when resolved is stopped before
      # systemd.services.systemd-resolved.stopIfChanged = false;
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
