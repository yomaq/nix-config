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
          kavita.enable = true;
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
        docker.enable = true;
        syncoid.enable = true;
        pods = {
          palworld.palhome.enable = true;
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
          host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHUuLHm+46zaQoCy0bsQLgAkQ+apfQsMjBTnpgWQQYqm";
          initrd = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBQW6mmDZldej3eTFaD3vr7OV8VFqYl7at5Ldg1P03M/";
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
