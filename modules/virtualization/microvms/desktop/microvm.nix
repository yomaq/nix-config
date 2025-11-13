{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
let
  vmName = "desktop";
  desktopUser = "desktop";
in
{
  imports = [
    ../microvm.nix
  ];
  
  config = {
    networking.hostName = "${vmName}";
    
    boot.initrd.kernelModules = [ "vkms" ];
    
    users.users.${desktopUser} = {
      isNormalUser = true;
      extraGroups = [ "input" "video" "render" ];
    };
    
    systemd.tmpfiles.rules = [
      "d /home/${desktopUser}/.config/sunshine 0700 ${desktopUser} users -"
    ];

    services.xserver.enable = true;
    services.xserver.displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    services.xserver.desktopManager.gnome.enable = true;
    
    services.displayManager.autoLogin = {
      enable = true;
      user = desktopUser;
    };
    
    services.gnome = {
      core-apps.enable = false;
      games.enable = false;
      gnome-keyring.enable = lib.mkForce false;
      gnome-settings-daemon.enable = true;
    };
    
    services.xserver.displayManager.gdm.autoSuspend = false;
    programs.dconf.profiles.user.databases = [{
      settings = {
        "org/gnome/desktop/screensaver" = {
          lock-enabled = false;
          lock-delay = lib.gvariant.mkUint32 0;
        };
        "org/gnome/desktop/session" = {
          idle-delay = lib.gvariant.mkUint32 0;
        };
      };
    }];

    environment.gnome.excludePackages = with pkgs; [
      gnome-tour
      gnome-connections
      epiphany
      geary
      evince
      totem
      gnome-music
      gnome-photos
    ];
    
    services.sunshine = {
      enable = true;
      autoStart = true;
    };
    
    environment.persistence."/persist/save" = lib.mkForce {
      directories = [
        "/home/${desktopUser}/.config/sunshine"
      ];
    };
    
    hardware.graphics.enable = true;
  };
}
