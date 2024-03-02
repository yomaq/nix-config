{ config, lib, pkgs, inputs, modulesPath, ... }:
{
  imports =[
    # import custom modules
    inputs.self.nixosModules.yomaq
    # import users
    (inputs.self + /users/admin)
  ];
  config = {
    networking.hostName = "nixos-install";

    services.getty.autologinUser = lib.mkDefault "admin";

    environment.systemPackages = with pkgs; [
      rsync
    ];
    networking.wireless.enable = lib.mkForce false;
    yomaq = {
      tailscale = {
        enable = true;
        extraUpFlags = ["--ssh=true" "--reset=true" ];
        # attempt to write the authkey in clear text into the nix store for the install-iso as it won't have a key to decrypt the secret
        authKeyFile = (pkgs.writeText "tailscaleAuthKey" (builtins.readFile config.age.secrets.tailscaleKeyAcceptSsh.path));
        preApprovedSshAuthkey = true;
      };
      timezone.central= true;
      suites = {
        basics.enable = true;
        foundation.enable = true;
      };
      # network.basics = lib.mkDefault false;
    };
  };
}
