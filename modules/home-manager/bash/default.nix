{ options, config, lib, pkgs, inputs, ... }:
let
  cfg = config.yomaq.bash;
in
{
  imports = [];
  options.yomaq.bash = {
    enable = with lib; mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom bash module
      '';
    };
  };
 config = lib.mkIf cfg.enable {
    programs = {
      bash = {
        enable = true;
        enableCompletion = true;
        initExtra = "";
      };
    };
 };
}
