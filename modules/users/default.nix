{ options, config, lib, pkgs, ... }:

let
  addPrefix = name: "./" + name;
in
{
  options.yomaq.users.users = lib.mkOpt {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of usernames";
    };
  imports = builtins.map addPrefix config.yomaq.users.users;
}