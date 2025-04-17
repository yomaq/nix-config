{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    inputs.self.users.yomaq
  ];
  config = lib.mkIf (config.yomaq.users.enableUsers != [ ]) {
    users.users = lib.listToAttrs (
      map (username: {
        name = username;
        value = {
          home = {
            _type = "override";
            content = "/Users/${username}";
            priority = 50;
          };
          gid = 
            if config.yomaq.users.users.${username}.isRoot then
              80 
            else
              20;
          shell = pkgs.zsh;
        };
      }) config.yomaq.users.enableUsers
    );
    environment.shells = [ pkgs.zsh ];

    homebrew = lib.foldl lib.recursiveUpdate {
      brewPrefix = "/opt/homebrew/bin";
      enable = true;
      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
        upgrade = true;
      };
    } (map (username: config.yomaq.users.users.${username}.homebrew) config.yomaq.users.enableUsers);

    home-manager = {
      extraSpecialArgs = {
        inherit inputs;
      };
      users = lib.listToAttrs (
        map (username: {
          name = username;
          value = {
            imports = [ inputs.self.homeManagerModules.yomaq ];
            config.home.stateVersion = "24.11";
            config.home.packages = config.yomaq.users.users.${username}.nixpkgs.common;
          };
        }) config.yomaq.users.enableUsers
      );
    };
  };
}
