{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.yomaq.comma;
in
{
  imports = [ inputs.nix-index-database.homeModules.nix-index ];
  options.yomaq.comma = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom comma module
      '';
    };
  };
  config = lib.mkIf cfg.enable { programs.nix-index-database.comma.enable = true; };
}
