# To make an installer iso, move this dir to ./hosts/nixos, commit changes.
# run `nixos-rebuild build-image --image-variant iso-installer --flake .#install-iso`
# move dir back to old. Currently the iso config throws erros when running `nix flake check` its possible those can be resolved, I'll look at that next time I need to rebuild a new iso.

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
    yomaq = {
      tailscale = {
        enable = true;
        extraUpFlags = [ "--advertise-tags=tag:acceptssh" ];
        # attempt to write the authkey in clear text into the nix store for the install-iso as it won't have a key to decrypt the secret
        authKeyFile = (
          pkgs.writeText "tailscaleAuthKey" (
            # enter key here when building the image. in /secrets/tailscaleOAuthKeyAcceptSsh.age
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
