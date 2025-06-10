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
        docker.enable = true;
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
        };
        syncoid = {
          isBackupServer = true;
          exclude = [
            "blue"
            "green"
            "wsl"
          ];
        };
      };

      smalt = {
        users.enableUsers = [ "admin" ];
        docker.enable = true;
        pods = {
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
        tailscale.preApprovedSshAuthkey = true;
        docker.enable = true;
        nixos-containers.code-server.enable = true;
      };

      wsl = {
        users.enableUsers = [ "admin" ];
        tailscale.authKeyFile = null;
        docker.enable = true;
        pods = {
          ollama.enable = true;
          speaches.enable = true;
        };
      };

      green = {
        users.enableUsers = [ "admin" ];
        docker.enable = true;
      };

      pearl = {
        users.enableUsers = [ "admin" ];
        tailscale.authKeyFile = null;
      };
    };
  };
}
