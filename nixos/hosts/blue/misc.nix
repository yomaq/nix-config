{ config, pkgs, ... }:

{
  imports =
    [ ];

  # Apparently... nixos can't declaratively manage flatpaks????????
  services.flatpak.enable = true;

  # Set default shell
  programs.zsh.enable = true;
  users.users.carln.shell = pkgs.zsh;
  environment.shells = with pkgs; [ zsh];

  # Tailscale
  services.tailscale = {
    enable = true;
  };

# 1Password 
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "carln" ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

}
