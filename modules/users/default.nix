{ options, config, lib, ... }:

let
  addPrefix = name: "./" + name;
  #test
in
{
  options.yomaq.users.users = lib.mkOpt {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of usernames";
    };
  imports = builtins.map "./" + config.yomaq.users.users;
}