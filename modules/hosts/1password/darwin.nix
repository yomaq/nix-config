{
  config,
  lib,
  ...
}:
let
  cfg = config.yomaq._1password;
in
{
  config = lib.mkIf cfg.enable {
    homebrew.casks = [
      "1password"
      "1password-cli"
    ];
  };
}
