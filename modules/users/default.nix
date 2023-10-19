{ options, config, lib, pkgs, ... }:


let
  cfg = config.yomaq.users;
  usersList = config.yomaq.users.users: "./" + ${config.yomaq.users.users};
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
    imports = [ usersList ];
  };
}