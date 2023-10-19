{ options, config, lib, pkgs, ... }:

let
  cfg = config.yomaq.users;
  addPrefix = name: "./" + name;
  listDirectories = builtins.map addPrefix cfg.users;
in
{
  options.yomaq.users = with types; {
    users = mkOpt (listOf str) [ ] "List of users";
  };
  imports = listDirectories;
}