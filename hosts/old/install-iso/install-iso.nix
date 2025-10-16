# To make an installer iso, move this dir to ./hosts/nixos, commit changes.
# run `nixos-rebuild build-image --image-variant iso-installer --flake .#install-iso`

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.yomaq
  ];
  config = {
    networking.hostName = "nixos-install";

    users.users.root.password = "k";

    services.openssh = {
      enable = true;
      settings.PermitRootLogin = "yes";
    };
    environment.persistence = lib.mkForce { };

    environment.systemPackages = with pkgs; [
      rsync
      vim
      git
    ];
    networking.wireless.enable = lib.mkForce false;
    inventory.hosts."${config.networking.hostName}".enable = false;

    systemd.services.tailscaled-autoconnect.serviceConfig = {
      Restart = "on-failure";
      RestartSec = "5s";
    };

    yomaq = {
      tailscale = {
        enable = true;
        extraUpFlags = [ "--advertise-tags=tag:acceptssh" ];
        # put the authkey in clear text into the nix store for the install-iso as it won't have a key to decrypt the secret
        authKeyFile = (
          pkgs.writeText "tailscaleAuthKey" (
            # tsauthkey goes here
            ""
          )
        );
      };
      timezone.central = true;
      nixSettings.enable = true;
      agenix.enable = true;
    };
  };
}
