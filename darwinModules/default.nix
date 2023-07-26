{ inputs, ... }@flakeContext:
{ config, lib, pkgs, ... }: {
  config = {
    documentation = {
      enable = false;
    };
    homebrew = {
      brewPrefix = "/opt/homebrew/bin";
      brews = [
        "mas"
      ];
      casks = [
        "moonlight"
        "1password"
        "raycast"
        "arc"
        "amethyst"
        "viscosity"
        "linearmouse"
        "altserver"
      ];
      enable = true;
      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
        upgrade = true;
      };
    };
    networking = {
      knownNetworkServices = [
        ''
          [
            "USB 10/100/1000 LAN"
            "Thunderbolt Bridge"
            "Wi-Fi"
          ]
        ''
      ];
      search = [
        "home.arpa"
      ];
    };
    nix = {
      gc = {
        automatic = true;
        interval = {
          Hour = 48;
        };
        options = "-d";
      };
      readOnlyStore = true;
      settings = {
        auto-optimise-store = true;
        sandbox = true;
      };
    };
    nixpkgs = {
      config = {
        allowUnfree = true;
      };
    };
    services = {
      nix-daemon = {
        enable = true;
      };
    };
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
      stateVersion = 4;
    };
    users = {
      users = {
        carln = {
          home = {
            _type = "override";
            content = /Users/carln;
            priority = 50;
          };
          name = "carln";
          shell = pkgs.bash;
        };
      };
    };
  };
}
