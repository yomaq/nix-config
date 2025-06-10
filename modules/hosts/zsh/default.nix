{
  lib,
  ...
}:
{
  options.yomaq.zsh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom zsh module
      '';
    };
  };
}
