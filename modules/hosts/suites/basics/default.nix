{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.yomaq.suites.basics;
in
{
  imports = [ ];
  options.yomaq.suites.basics = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = '''';
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ inputs.agenix.overlays.default ];
    environment.systemPackages = with pkgs; [
      vim
      git
      agenix
      just
      nixos-rebuild
    ];
  };
}
