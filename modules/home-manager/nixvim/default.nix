{ options, config, lib, pkgs, inputs, ... }:
let
  cfg = config.yomaq.nixvim;
in
{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];
  options.yomaq.nixvim = {
    enable = with lib; mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom nixvim module
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    programs.nixvim = {
      enable = true;

      options = {
        number = true;
        shiftwidth = 2;
      };
      colorschemes.dracula.enable = true;
      plugins = {
        lightline.enable = true;
        nix.enable = true;
      };
    };
  };
}
