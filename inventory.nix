{
  config,
  lib,
  ...
}:
{
  config.inventory = {
    hosts = {

      azure = {
        users.enableUsers = [ "admin" ];
        publicKey = {
          host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP2G2qPq4NAu18EE0CB7Kfm5F3FIvphuzv13BlCXuKbu";
          initrd = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICx7kM94EWaUxMh9oVgLapk4+beUqCYge3Qd4fjCRyD0";
        };
        docker.enable = true;
        syncoid.enable = true;
        pods = {
          golink.enable = true;
          teslamate.enable = true;
          dufs.enable = true;
          changedetection.enable = true;
          linkwarden.enable = true;
          searxng.enable = true;
          n8n.enable = true;
          open-webui.enable = true;
        };
        nixos-containers = {
          nextcloud = {
            enable = true;
            storage = config.yomaq.impermanence.backupStorage;
          };
          homepage.enable = true;
          ntfy.enable = true;
          gatus.enable = true;
          tsidp.enable = true;
          audiobookshelf.enable = true;
          calibre-web.enable = true;
        };
        syncoid = {
          isBackupServer = true;
        };
      };

      smalt = {
        users.enableUsers = [ "admin" ];
        publicKey = {
          host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILR615VGZfPxDnK6dDumGUByl8n8ZT8hctQ0HzXplxPB";
          initrd = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKFphObpjw/XH1NvvI2VuQPlLb45Zi3O7CgFQAH4fkvz";
        };
        docker.enable = true;
        syncoid.enable = true;
        pods = {
          foundry-vtt.enable = true;
          palworld.palhome.enable = true;
          necesse.necesse1.enable = true;
          minecraftBedrock.minecrafthome = {
            enable = true;
            envVariables = {
              "version" = "1.21.60.10";
              "EULA" = "TRUE";
              "gamemode" = "survival";
              "difficulty" = "hard";
              "allow-cheats" = "true";
              "max-players" = "10";
              "view-distance" = "50";
              "tick-distance" = "4";
              "TEXTUREPACK_REQUIRED" = "true";
            };
          };
        };
      };

      teal = {
        users.enableUsers = [ "admin" ];
        publicKey = {
          host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK7JriToIhfbruPxV0TJI9SF2nTKINmlsnSoyDdAVVoY";
          initrd = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBX5raO/z+XWBKjOU4JwGvquTMYSgxcg+tCFU3ok5s6H";
        };
        syncoid.enable = true;
        docker.enable = true;
        nixos-containers.code-server.enable = true;
      };

      wsl = {
        users.enableUsers = [ "admin" ];
        publicKey.host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAjI4UDrAlASD2wocv7lHClFdf9pIqPzyGTzWAvbCLyX";
        docker.enable = true;
        syncoid.enable = false;
        pods = {
          ollama.enable = true;
          speaches.enable = true;
        };
      };

      green = {
        users.enableUsers = [ "admin" ];
        publicKey = {
          host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMOlUAUwZ7o0oW5IfWaPOrAcxfrxALyeJSMxOSgwuCPx";
          initrd = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH4VvHT7WFFaSu9A9nNgI+32bCLvO4eVd2rYWxkGBsff";
        };
        syncoid.enable = true;
        docker.enable = true;
      };

      jade = {
        users.enableUsers = [ "admin" ];
        publicKey = {
          host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILD1hmWlgAmu+A9p+OBAaAdnHsibVW82U0j4N7KZNyWi";
          initrd = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMHclCCb3Aq9Xl8vAslAq9CeVuavtfqPrkh/I3smdDCa";
        };
        syncoid.enable = true;
        docker.enable = true;
      };
    
      moss = {
        users.enableUsers = [ "admin" ];
        publicKey = {
          host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINwOScam4G2piPGqwM8qrfLoQCUzJF5cDLPvmbkouf//";
          initrd = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+bidgd5iUcrB2z/YNyZUsCmdBHbcG+zxm8hlY/fHki";
        };
        syncoid.enable = true;
        docker.enable = true;
      };

      pearl = {
        users.enableUsers = [ "admin" ];
        publicKey.host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHX2aVm/O7Zs0qWzhU1I2xNH8JNx6q1HTy50epYqEXBI";
        syncoid.enable = true;
      };
    };
  };
}
