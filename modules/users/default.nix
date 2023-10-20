{ options, config, lib, pkgs, ... }:

let
  inherit (lib) mkOption types map;
in
{
  options.yomaq.users.users = mkOption {
      type = types.listOf types.str;
      default = [ "admin" ];
      description = "List of usernames";
    };
  imports = map (username: "./${username}") config.yomaq.users.users;
}