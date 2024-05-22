{ config, lib, pkgs, inputs, modulesPath, ... }:
{
  imports =[
    # import users
      inputs.self.nixosModules.yomaq
  ];
  config = {
    networking.hostName = "nixos-install";

    users.users.root.initialPassword = "k";

    environment.systemPackages = with pkgs; [
      rsync
    ];
    networking.wireless.enable = lib.mkForce false;
    yomaq = {
      tailscale = {
        enable = true;
        extraUpFlags = ["--reset=true" ];
        # attempt to write the authkey in clear text into the nix store for the install-iso as it won't have a key to decrypt the secret
        authKeyFile = (pkgs.writeText "tailscaleAuthKey" (builtins.readFile config.age.secrets.tailscaleOAuthKeyAcceptSsh.path));
        preApprovedSshAuthkey = true;
      };
      timezone.central= true;
      suites = {
        basics.enable = true;
        # foundation.enable = true;
      };
      nixSettings.enable = true;
      # initrd-tailscale.enable = lib.mkDefault false;
      # network.basics = lib.mkDefault false;
    };
  };
}