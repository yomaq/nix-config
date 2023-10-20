{ options, config, lib, ... }:


{
  options.yomaq.users.users = lib.mkOpt {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of usernames";
    };

  imports = "./" + config.yomaq.users.users;
}