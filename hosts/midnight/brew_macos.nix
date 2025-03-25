{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = {

    #Some programs don't have nix packages available, so making use of Homebrew is needed, sadly there is also no way of installing home brew through nix
    homebrew = {
      casks = [
        "moonlight"
        "raycast"
        "arc"
        "linearmouse"
        "spotify"
        "nextcloud"
        "brave-browser"
        "zen-browser"
        "obsidian"
      ];
      taps = [ "pulumi/tap" ];
      brews = [
        "pulumi"
        "pulumi/tap/crd2pulumi"
        "pulumi/tap/kube2pulumi"
      ];
    };
    #User specific settings, eventually plan to create the user account itself through Nix as well
    users = {
      users = {
        carln = {
          home = {
            _type = "override";
            content = /Users/carln;
            priority = 50;
          };
          name = "carln";
          shell = pkgs.zsh;
        };
      };
    };
  };
}
