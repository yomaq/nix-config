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
    environment.persistence = lib.mkForce {};


    environment.systemPackages = with pkgs; [ rsync vim git ];
    networking.wireless.enable = lib.mkForce false;
    yomaq = {
      tailscale = {
        enable = true;
        extraUpFlags = [ "--advertise-tags=tag:acceptssh" ];
        # attempt to write the authkey in clear text into the nix store for the install-iso as it won't have a key to decrypt the secret
        authKeyFile = (
          pkgs.writeText "tailscaleAuthKey" (
            builtins.readFile config.age.secrets.tailscaleOAuthKeyAcceptSsh.path
          )
        );
        preApprovedSshAuthkey = true;
      };
      timezone.central = true;
      nixSettings.enable = true;
      agenix.enable = true;
    };
  };
}
