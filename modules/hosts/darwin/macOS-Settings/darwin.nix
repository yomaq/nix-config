{
  config,
  lib,
  ...
}:
let
  cfg = config.yomaq.macosSettings;
in
{
  options.yomaq.macosSettings = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom enablesettings
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    #MacOS settings for Dock, Finder, etc

    security.pam.services.sudo_local.touchIdAuth = true;

    system = {
      defaults = {
        NSGlobalDomain = {
          AppleInterfaceStyle = "Dark";
          NSDocumentSaveNewDocumentsToCloud = false;
          "com.apple.springing.enabled" = true;
        };
        SoftwareUpdate = {
          AutomaticallyInstallMacOSUpdates = false;
        };
        dock = {
          autohide = true;
          autohide-delay = 0.1;
          autohide-time-modifier = null;
          expose-animation-duration = null;
          mineffect = "genie";
          mru-spaces = false;
          orientation = "bottom";
          show-process-indicators = true;
          show-recents = false;
          static-only = true;
        };
        finder = {
          AppleShowAllExtensions = true;
          AppleShowAllFiles = true;
          CreateDesktop = false;
          ShowStatusBar = true;
          _FXShowPosixPathInTitle = true;
        };
        loginwindow = {
          DisableConsoleAccess = true;
        };
      };
    };
  };
}
