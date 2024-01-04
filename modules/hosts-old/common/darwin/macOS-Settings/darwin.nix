{ config, lib, pkgs, ... }: {
#MacOS settings for Dock, Finder, etc
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
}