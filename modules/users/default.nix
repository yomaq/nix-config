{ options, config, lib, pkgs, ... }:

with lib;
let
  cfg = config.yomaq.users;
  addPrefix = name: "./" + name;
in
{
  options = {
    cfg.users = lib.mkOption {
      type = lib.types.listOf lib.types.string;
      default = [];
      description = "List of usernames";
    };
  };

  config = {
    imports = lib.map addPrefix cfg.users;
  };
}