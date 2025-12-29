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
          SSH_DOMAIN = "${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net";
          SSH_PORT = lib.head config.services.openssh.ports;
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
    services.openssh.settings.AcceptEnv = "GIT_PROTOCOL";

    yomaq.tailscale.extraUpFlags = [
      "--ssh=false"
      "--reset=true"
      "--accept-dns=true"
    ];

    virtualisation.docker = {
      enable = true;
      daemon.settings = {
        dns = [ "100.100.100.100" ];
      };
    };

    # Allow Docker containers to access Forgejo
    networking.firewall.extraCommands = ''
      iptables -A INPUT -i docker+ -p tcp --dport 443 -j ACCEPT
      iptables -A INPUT -i br-+ -p tcp --dport 443 -j ACCEPT
    '';

    age.secrets.forgejoRunnerToken.file = (inputs.self + /secrets/forgejoRunnerToken.age);
    services.gitea-actions-runner = {
      package = pkgs.forgejo-runner;
      instances."default" = {
        enable = true;
        name = "forgejo-nix-runner";
        url = "https://${vmName}.${config.yomaq.tailscale.tailnetName}.ts.net";
        tokenFile = config.age.secrets.forgejoRunnerToken.path;
        labels = [
          "ubuntu-latest:docker://node:latest"
          "nix:docker://nixpkgs/nix-flakes:latest"
          "alpine:docker://alpine:latest"
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
