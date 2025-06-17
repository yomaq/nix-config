{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  listOfUsers =
    if config ? inventory.hosts."${config.networking.hostName}".users.enableUsers then
      config.inventory.hosts."${config.networking.hostName}".users.enableUsers
      ++ config.yomaq.users.enableUsers
    else
      config.yomaq.users.enableUsers;
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.self.users.yomaq
  ];
  config = lib.mkIf (listOfUsers != [ ]) {

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
            username:
            (
              config.yomaq.users.users.${username}.hasNixosPassword
              || config.yomaq.users.users.${username}.u2fAuth
            )
          ) listOfUsers
        )
    );

    systemd.tmpfiles.rules = (
      builtins.concatLists (
        map (username: [
          "d /home/${username}/.config/Yubikey 0700 ${username} - -"
          "C+ /home/${username}/.config/Yubikey/u2f_keys 0600 ${username} users - ${
            config.age.secrets.${username}.path
          }"
        ]) (builtins.filter (username: config.yomaq.users.users.${username}.u2fAuth) listOfUsers)
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
      }) listOfUsers
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
        }) listOfUsers
      );
    };

    security.sudo.extraRules =
      let
        passwordlessAdmins = lib.filter (
          username:
          config.yomaq.users.users.${username}.isRoot
          && !config.yomaq.users.users.${username}.hasNixosPassword
        ) listOfUsers;
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
        }) listOfUsers
      );
    };
  };
}
