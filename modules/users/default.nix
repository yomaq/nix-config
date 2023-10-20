{ options, config, lib, pkgs, ... }:

let
  cfg = config.yomaq.users;
  addPrefix = name: "./" + name;
  listDirectories = builtins.map addPrefix config.yomaq.users.users;
in
{
  options.yomaq.users.users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ admin ];
      description = "List of usernames";
    };
  imports = listDirectories;
}