{ config, lib, pkgs, inputs, ... }:

let
  flakeUrl = "github:yomaq/nix-config";
  
  createMicroVM = name: {
    "microvm-create-${name}" = {
      description = "Create MicroVM ${name} if it does not exist";
      wantedBy = [ 
        "microvm-virtiofsd@${name}.service"
        "microvm-tap-interfaces@${name}.service"
      ];
      before = [
        "microvm-virtiofsd@${name}.service"
        "microvm-tap-interfaces@${name}.service"
      ];
      after = [ 
        "network-online.target" 
        "systemd-tmpfiles-setup.service"
      ];
      wants = [ "network-online.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      
      script = ''
        if [ ! -d "/var/lib/microvms/${name}" ]; then
          echo "Creating ${name}..."
          ${inputs.microvm.packages.${pkgs.system}.microvm}/bin/microvm -f ${flakeUrl} -c ${name}
        else
          echo "${name} already exists"
        fi
      '';
    };
  };

  createMicroVMUpdate = name: {
    "microvm-update-${name}" = {
      description = "Update MicroVM ${name}";
      serviceConfig = {
        Type = "oneshot";
      };
      script = ''
        echo "Checking updates for ${name}..."
        if ${inputs.microvm.packages.${pkgs.system}.microvm}/bin/microvm -u ${name} | grep -q "Reboot MicroVM ${name}"; then
          echo "Restarting ${name}..."
          systemctl restart microvm@${name}.service
        fi
      '';
    };
  };

  createMicroVMDirs = name: [
    "d /persist/save/microvm/${name} 0755 root root"
    "d /persist/microvm/${name} 0755 root root"
    "d /persist/microvm/${name}/tailscale 0755 root root"
    "d /persist/microvm/${name}/ssh 0755 root root"
  ];
in
{
  imports = [ inputs.microvm.nixosModules.host ];

  options = {
    inventory.hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.microvms = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
        }
      );
    };
  };

  config = lib.mkMerge [
    {
      microvm.autostart = config.inventory.hosts."${config.networking.hostName}".microvms;

      systemd.tmpfiles.rules = lib.flatten (
        map createMicroVMDirs config.microvm.autostart
      );

      systemd.services = lib.mkMerge (
        (map createMicroVM config.microvm.autostart) ++
        (map createMicroVMUpdate config.microvm.autostart)
      );
    }
    
    (lib.mkIf (config.yomaq.autoUpgrade.enable && config.microvm.autostart != []) {
      systemd.services.nixos-upgrade = {
        serviceConfig.ExecStartPost = map (service: 
          "${pkgs.systemd}/bin/systemctl start ${service}"
        ) (map (name: "microvm-update-${name}.service") config.microvm.autostart);
      };
    })
  ];
}
