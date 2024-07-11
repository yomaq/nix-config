{ options, config, lib, pkgs, inputs, ... }:
let
  cfg = config.yomaq.direnv;
in
{
  imports = [];
  options.yomaq.direnv = {
    enable = with lib; mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom direnv module
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      direnv = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };
    };
  };
}
