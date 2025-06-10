{
  lib,
  ...
}:
{
  options.yomaq._1password = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom 1password module
      '';
    };
  };
}
