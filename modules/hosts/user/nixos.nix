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
    inputs.home-manager.nixosModules.home-manager
    inputs.self.users.yomaq
  ];
  config = lib.mkIf (config.yomaq.users.enableUsers != [ ]) {

    users.mutableUsers = false;
    users.allowNoPasswordLogin = true;

    age.secrets = lib.listToAttrs (
      map
        (username: {
          name = username;
          value = {
            file = (inputs.self + /secrets/${username}.age);
          };
        })
        (
          builtins.filter (
            username: config.yomaq.users.users.${username}.hasNixosPassword
          ) config.yomaq.users.enableUsers
        )
    );

    users.users = lib.listToAttrs (
      map (username: {
        name = username;
        value = {
          shell = pkgs.zsh;
          isNormalUser = true;
          description = username;
          hashedPassword = lib.mkIf (!config.yomaq.users.users.${username}.hasNixosPassword) null;
          hashedPasswordFile =
            lib.mkIf config.yomaq.users.users.${username}.hasNixosPassword
              config.age.secrets.${username}.path;
          openssh.authorizedKeys.keys = config.yomaq.users.users.${username}.authSshKeys;
          extraGroups = (if config.yomaq.users.users.${username}.isRoot then [ "wheel" ] else [ ]) ++ [
            "networkmanager"
          ];
          packages = with pkgs; [ ];
        };
      }) config.yomaq.users.enableUsers
    );

    environment.persistence."${config.yomaq.impermanence.dontBackup}" = {
      users = lib.listToAttrs (
        map (username: {
          name = username;
          value = {
            directories = [
              "nix"
              "documents"
              ".var"
              ".config"
              ".local"
            ];
            files = [ ];
          };
        }) config.yomaq.users.enableUsers
      );
    };

    security.sudo.extraRules =
      let
        passwordlessAdmins = lib.filter (
          username:
          config.yomaq.users.users.${username}.isRoot
          && !config.yomaq.users.users.${username}.hasNixosPassword
        ) config.yomaq.users.enableUsers;
      in
      lib.mkIf (passwordlessAdmins != [ ]) [
        {
          users = passwordlessAdmins;
          commands = [
            {
              command = "ALL";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];

    home-manager = {
      extraSpecialArgs = {
        inherit inputs;
      };
      users = lib.listToAttrs (
        map (username: {
          name = username;
          value = {
            imports = [ inputs.self.homeManagerModules.yomaq ];
            config.home.stateVersion = config.system.stateVersion;
            config.home.packages =
              config.yomaq.users.users.${username}.nixpkgs.nixos
              ++ config.yomaq.users.users.${username}.nixpkgs.common;
          };
        }) config.yomaq.users.enableUsers
      );
    };
  };
}
