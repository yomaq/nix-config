{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
let
  vmName = "forgejo";
in
{
  imports = [
    ../microvm.nix
  ];
  config = {
    networking.hostName = "${vmName}";

    microvm = {
      vcpu = 4;
      hotplugMem = 16384;
    };

    services.forgejo = {
      enable = true;
      database.type = "mysql";

      settings = {
        server = {
          DOMAIN = "${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net";
          ROOT_URL = "https://${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net/";
          HTTP_PORT = 3000;
        };
        service = {
          DISABLE_REGISTRATION = false;
          ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
        };
        oauth2_client = {
          REGISTER_EMAIL_CONFIRM = false;
          ACCOUNT_LINKING = "auto";
        };
        actions = {
          ENABLED = true;
        };
      };

    };

    virtualisation.docker.enable = true;

    age.secrets.forgejoRunnerToken.file = (inputs.self + /secrets/forgejoRunnerToken.age);
    services.gitea-actions-runner = {
      package = pkgs.forgejo-runner;
      instances."default" = {
        enable = true;
        name = "forgejo-nix-runner";
        url = "https://${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net";
        tokenFile = config.age.secrets.forgejoRunnerToken.path;
        labels = [
          "nix:docker://nixpkgs/nix-flakes:latest"
        ];
      };
    };

    services.caddy = {
      enable = true;
      virtualHosts."${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net".extraConfig = ''
        reverse_proxy 127.0.0.1:3000
      '';
    };

    environment.persistence."/persist/save" =  {
      directories = [
        "/var/lib"
      ];
    };
  };
}
