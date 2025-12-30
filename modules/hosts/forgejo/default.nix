{
  config,
  lib,
  ...
}:

{
  options.yomaq.forgejoUrl = lib.mkOption {
    type = lib.types.str;
    default = "https://forgejo.${config.yomaq.tailscale.tailnetName}.ts.net";
  };
}
