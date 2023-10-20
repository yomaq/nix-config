{ options, config, lib, pkgs, ... }:

let
  inherit (lib) mkOption types;
  # addPrefix = name: "./" + name;
  # listDirectories = builtins.map addPrefix config.yomaq.users.users;
in
{
  options.yomaq.users.users = mkOption {
      type = types.listOf types.str;
      default = [ "admin" ];
      description = "List of usernames";
    };
  # imports = listDirectories;
}