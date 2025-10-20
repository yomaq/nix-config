{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  listOfUsers = config.inventory.hosts."${config.networking.hostName}".users.enableUsers;
in
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    inputs.self.users.yomaq
  ];
  config = lib.mkIf (listOfUsers != [ ]) {
    users.users = lib.listToAttrs (
      map (username: {
        name = username;
        value = {
          home = {
            _type = "override";
            content = "/Users/${username}";
            priority = 50;
          };
          gid = if config.yomaq.users.users.${username}.isRoot then 80 else 20;
          shell = pkgs.zsh;
        };
      }) listOfUsers
    );
    environment.shells = [ pkgs.zsh ];

    nix.settings.trusted-users = 
      let
        rootUsers = builtins.filter (
          username: config.yomaq.users.users.${username}.isRoot
        ) listOfUsers;
      in
      [ "root" ] ++ rootUsers;

    homebrew = lib.foldl lib.recursiveUpdate {
      brewPrefix = "/opt/homebrew/bin";
      enable = true;
      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
        upgrade = true;
      };
    } (map (username: config.yomaq.users.users.${username}.homebrew) listOfUsers);

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
        }) listOfUsers
      );
    };
  };
}
