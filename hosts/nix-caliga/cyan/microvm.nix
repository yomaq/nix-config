{ inputs, pkgs, ... }:

let
  vmName = "audiobookshelf";
in
{
  imports = [ inputs.microvm.nixosModules.host ];

  age.secrets.tailscaleKey.file = inputs.self + /secrets/tailscaleKey.age;

  layeredImage.contents = [
    (pkgs.runCommand "persist-link" { } ''
      mkdir -p $out
      ln -s var/persist $out/persist
    '')
  ];

  
  systemd.tmpfiles.rules = [
    "d /var/persist 0755 root root -"
    "d /var/persist/microvm 0755 root root -"
    "d /var/persist/microvm/${vmName} 0755 root root -"
    "d /var/persist/microvm/${vmName}/ssh 0755 root root -"
    "d /var/persist/save 0755 root root -"
    "d /var/persist/save/microvm 0755 root root -"
    "d /var/persist/save/microvm/${vmName} 0755 root root -"
  ];

  # just for testing
  # need the bridge that the existing audiobookshelv microvm module expects
  systemd.services.microvm-br0 = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "NetworkManager.service"
      "microvm-tap-interfaces@${vmName}.service"
    ];
    requires = [ "microvm-tap-interfaces@${vmName}.service" ];
    before = [ "microvm@${vmName}.service" ];
    requiredBy = [ "microvm@${vmName}.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      /usr/bin/nmcli connection show br0 >/dev/null 2>&1 \
        || /usr/bin/nmcli connection add type bridge con-name br0 ifname br0 \
             ipv4.method shared ipv4.addresses 10.0.0.1/24 bridge.stp no
      /usr/bin/nmcli connection up br0
      ${pkgs.iproute2}/bin/ip link set vm-ookshelf master br0 up
    '';
  };

  # the existing microvm configuration for audiobookshelf
  microvm.vms.${vmName}.flake = inputs.self;
}
