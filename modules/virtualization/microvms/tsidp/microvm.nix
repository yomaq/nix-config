{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
let
  vmName = "tsidp";
  # Systemd service will eventually be replaced by the module coming in nixos 25.11
in
{
  imports = [
    ../microvm.nix
  ];
  config = {
    networking.hostName = "${vmName}";

    systemd.tmpfiles.rules = [ "d /persist/save/tsidp 0700 root root" ];

    systemd.services.tsidp = {
      description = "Tailscale OIDC Identity Provider";
      wantedBy = [ "multi-user.target" ];
      requires = [ "tailscaled.service" ];

      serviceConfig = {
        ExecStartPre = pkgs.writeShellScript "wait-for-tailscale" ''
          while ! ${pkgs.unstable.tailscale}/bin/tailscale status &>/dev/null; do
            echo "Waiting for tailscale to be ready..."
            sleep 1
          done
        '';
        ExecStart = "${pkgs.unstable.tsidp}/bin/tsidp --use-local-tailscaled=true --dir=/persist/save/tsidp --port=443";
        Environment = [ "TAILSCALE_USE_WIP_CODE=1" ];
        Restart = "always";
      };
    };

  };
}
