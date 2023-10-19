{ options, config, lib, pkgs, ... }:


let
  cfg = config.yomaq.users;
in
{
  options.yomaq.users = with types; {
    users =  mkOpt (listOf str) [ ] "List of users";
  };

  config = {
    import = [ cfg.users ]
  };
}