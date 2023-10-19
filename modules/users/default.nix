{ options, config, lib, pkgs, ... }:


let
  cfg = config.yomaq.users;
in
{
  options.yomaq.users = with types; {
    users = mkOpt attrs { };
  };

  config = {
    import = [ cfg.users ]
  };
}