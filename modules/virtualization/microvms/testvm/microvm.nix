{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
let
  serviceName = "testvm";
in
{
  imports = [
    inputs.self.nixosModules.yomaq
    inputs.microvm.nixosModules.microvm
  ];
  config = {
    system.stateVersion = config.system.nixos.release;
    microvm = {
      hypervisor = "cloud-hypervisor";
      vcpu = 1;
      hotplugMem = 1536;
      shares = [
        {
          source = "/nix/store";
          mountPoint = "/nix/.ro-store";
          tag = "${serviceName}store";
          proto = "virtiofs";
          readOnly = true;
        }
        {
          source = "/run/agenix";
          mountPoint = "/run/agenix";
          tag = "${serviceName}a";
          proto = "virtiofs";
          readOnly = true;
        }
        {
          source = "/persist/microvm/${serviceName}/ssh";
          mountPoint = "/etc/ssh";
          tag = "${serviceName}ssh";
          proto = "virtiofs";
        }
        {
          source = "/persist/microvm/${serviceName}/tailscale";
          mountPoint = "/var/lib/tailscale";
          tag = "${serviceName}ts";
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
      writableStoreOverlay = "/nix/.rw-store";
      volumes = [
        {
          image = "nix-store-overlay.img";
          mountPoint = "/nix/.rw-store";
          size = 2048;
        }
      ];
      
      interfaces = [
        {
          type = "tap";
          id = "vm-${
            if builtins.stringLength serviceName <= 8
            then serviceName
            else builtins.substring (builtins.stringLength serviceName - 8) 8 serviceName
          }";
          mac = let
            hash = builtins.hashString "sha256" serviceName;
            octets = lib.genList (i: builtins.substring (i * 2) 2 hash) 5;
          in "02:${lib.concatStringsSep ":" octets}";
        }
      ];
    };
    
    yomaq.gatus.enable = true;

    systemd.services.gatus.serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";

    services.gatus = {
      enable = true;
      settings = {
        web.port = 8080;
        storage = {
          type = "sqlite";
          path = "/var/lib/gatus/data.db";
        };

        alerting = {
          ntfy = {
            url = "${config.yomaq.ntfy.ntfyUrl}";
            topic = "${config.yomaq.ntfy.defaultTopic}";
            priority = 3;
            default-alert = {
              enable = true;
              failure-threshold = 10;
              success-threshold = 10;
              send-on-resolved = true;
            };
          };
        };
      };
    };
    services.caddy = {
      enable = true;
      virtualHosts."${serviceName}.${config.yomaq.tailscale.tailnetName}.ts.net".extraConfig = ''
        reverse_proxy 127.0.0.1:8080
      '';
    };

    environment.persistence."${config.yomaq.impermanence.backup}".directories = [ "/var/lib" ];
    fileSystems."/persist/save".neededForBoot = true;

    systemd.tmpfiles.rules = [
      "d /persist/gatus 0755 root root"
    ];

    networking.hostName = "${serviceName}";
    yomaq = {
      suites.microvm.enable = true;
    };
  };
}
