{ options, config, lib, pkgs, ... }:

with lib;
let
  cfg = config.yomaq.users;
  addPrefix = name: "./" + name;
  listDirectories = lib.map addPrefix cfg.users;
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
    imports = listDirectories;
  };
}