{ options, config, lib, pkgs, ... }:

let
  cfg = config.yomaq.users;
  addPrefix = name: "./" + name;
  #listDirectories = builtins.map addPrefix cfg.users;
in
{
  options.yomaq.users.users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of usernames";
    };


  imports = builtins.map addPrefix cfg.users;

}