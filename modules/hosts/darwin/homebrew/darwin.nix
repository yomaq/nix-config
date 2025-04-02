{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.yomaq.homebrew;
in
{
  options.yomaq.homebrew = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = '''';
    };
  };
  config = lib.mkIf cfg.enable {
    #Some programs don't have nix packages available, so making use of Homebrew is needed, sadly there is also no way of installing home brew through nix
    homebrew = {
      brewPrefix = "/opt/homebrew/bin";
      brews = [ "mas" ];
      enable = true;
      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
        upgrade = true;
      };
    };
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
  };
}
