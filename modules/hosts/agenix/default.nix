{
  lib,
  ...
}:
{
  options.yomaq.agenix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom agenix module
      '';
    };
  };
}
