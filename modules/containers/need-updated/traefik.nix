{
  config,
  lib,
  ...
}:
with lib;
let
  ### Set container name and image
  NAME = "traefik";
  IMAGE = "docker.io/traefik";
  defaultVersion = "v3.0";
  cfg = config.yomaq.pods.${NAME};
in
{
  options.yomaq.pods.${NAME} = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom ${NAME} container module
      '';
    };
    imageVersion = mkOption {
      type = types.str;
      default = defaultVersion;
      description = ''
        container image version
      '';
    };
  };
  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      ### main container
      "${NAME}" = {
        image = "${IMAGE}:${cfg.imageVersion}";
        autoStart = true;
        environment = {
        };
        cmd = [
          # certificat resolvers
          "--certificatesresolvers.tailscale.tailscale=true"
          # docker provider
          "--providers.docker=true"
          "--providers.docker.exposedbydefault=false"
          #entrypoints and redirections
          "--entrypoints.web.address=:80"
          "--entrypoints.web.http.redirections.entryPoint.to=websecure"
          "--entrypoints.web.http.redirections.entryPoint.scheme=https"
          "--entrypoints.websecure.address=:443"
          # accept self signed certificates from traefik to the service
          "--serversTransport.insecureSkipVerify=true"
        ];
        ports = [
          "80:80"
          "443:443"
        ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock:ro"
          "/var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock:ro"
        ];
        extraOptions = [
          "--pull=always"
        ];
      };
      ### test container
      # "${NAME}test" = {
      #   image = "traefik/whoami:latest";
      #   autoStart = true;
      #   environment = { };
      #   cmd = [ ];
      #   ports = [];
      #   volumes = [ ];
      #   extraOptions = [ ];
      #   labels = {
      #     "traefik.enable" = "true";
      #     "traefik.http.routers.whoami.rule" = "Host(`whoami.${hostName}.${tailnetName}.ts.net`)";
      #     "traefik.http.routers.whoami.entrypoints" = "websecure";
      #     "traefik.http.routers.whoami.tls.certresolver" = "tailscale";
      #   };
      # };
    };
  };
}
