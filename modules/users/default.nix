{ options, config, lib, pkgs, ... }:

let
  cfg = config.yomaq.users;
  addPrefix = name: "./" + name;
  listDirectories = builtins.map addPrefix cfg.users;
in
{
  options.yomaq.users.users = lib.mkOption {
      type = lib.types.listOf lib.types.string;
      default = [];
      description = "List of usernames";
    };

  config = {
    imports = listDirectories;
  };
}