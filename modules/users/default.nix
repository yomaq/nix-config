{ options, config, lib, pkgs, ... }:


let
  cfg = config.yomaq.users;
  usersList = lib.mapAttrsToList (name: _: "./${name}") config.yomaq.users.users;
in
{
  options.yomaq.users = with types; {
    users = mkOpt attrs { };
  };

  config = {
    imports = lib.map (dir: { file = dir; }) usersList;
  };
}