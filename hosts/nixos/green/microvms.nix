{
  config,
  lib,
  inputs,
  ...
}:
let
  MICROVMNAME = "my-microvm1";
  serviceName = "${config.networking.hostName}-${MICROVMNAME}";
  cfg = config.microvm.vms."${MICROVMNAME}";
in
{
  imports = [ inputs.microvm.nixosModules.host ];
  config = {

    microvm = {
      autostart = [
        "${MICROVMNAME}"
      ];
    };

    systemd.tmpfiles.rules = [
      "d /persist/save/microvm/${serviceName} 0755 root root"
      "d /persist/microvm/${serviceName} 0755 root root"
    ];

    microvm.vms = {
      "${MICROVMNAME}" = {
        # The package set to use for the microvm. This also determines the microvm's architecture.
        # Defaults to the host system's package set if not given.
        pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };

        # (Optional) A set of special arguments to be passed to the MicroVM's NixOS modules.
        specialArgs = { inherit inputs; };

        # The configuration for the MicroVM.
        # Multiple definitions will be merged as expected.
        config = {
          imports = [
            inputs.self.nixosModules.yomaq
          ];
          # It is highly recommended to share the host's nix-store
          # with the VMs to prevent building huge images.
          microvm.shares = [{
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
            tag = "${serviceName}store";
            proto = "virtiofs";
          }
          {
            source = "/run/agenix";
            mountPoint = "/run/agenix";
            tag = "${serviceName}a";
            proto = "virtiofs";
          }
          {
            source = "/persist/save/microvm/${serviceName}";
            mountPoint = "/persist/save";
            tag = "${serviceName}ps";
            proto = "virtiofs";
          }
          {
            source = "/persist/microvm/${serviceName}";
            mountPoint = "/persist";
            tag = "${serviceName}p";
            proto = "virtiofs";
          }
          ];

          fileSystems."/persist".neededForBoot = true;
          fileSystems."/persist/save".neededForBoot = true;

          environment.persistence."${config.yomaq.impermanence.dontBackup}" = {
            hideMounts = true;
            directories = [
              "/etc/ssh"
            ];
          };

          microvm.writableStoreOverlay = "/nix/.rw-store";

          microvm.volumes = [ {
            image = "nix-store-overlay.img";
            mountPoint = "/nix/.rw-store";
            size = 2048;
          } ];

          microvm = {
            hypervisor = "cloud-hypervisor";
            # ...add additional MicroVM configuration here
            interfaces = [
              {
                type = "tap";
                id = "vm-${builtins.substring (builtins.stringLength serviceName - 8) 8 serviceName}";
                mac = "02:00:00:00:00:04";
              }
            ];
          };

          users.users.root.password = "k";

          systemd.network.enable = true;

          # systemd.network.networks."20-lan" = {
          #   matchConfig.Type = "ether";
          #   networkConfig = {
          #     DHCP = "yes";
          #   };
          # };

          networking.hostName = "${serviceName}";
          inventory.hosts."${serviceName}".users.enableUsers = [ "admin" ];
          age.identityPaths = [ "/etc/ssh/${config.networking.hostName}" ];

          nixpkgs.overlays = [
              inputs.self.overlays.pkgs-unstable
              inputs.agenix.overlays.default
            ];

          yomaq = {
            agenix.enable = true;
            zsh.enable = true;
            ssh.enable = true;
            tailscale = {
                enable = true;
                extraUpFlags = [
                  "--ssh=true"
                  "--reset=true"
                ];
            };
          };
        };
      };
    };
  };
}
