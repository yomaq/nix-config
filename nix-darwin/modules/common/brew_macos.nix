{ config, lib, pkgs, ... }: {
  config = {
    programs = {
#Generally avoid installing generic packages in darwin rather than homeManager, however zsh paths are broken without enabling it in nixDarwin as well
      zsh = {
        enable = true;
      };
    };
#At the time of making the config nix breaks when darwin documentation is enabled.
    documentation = {
      enable = false;
    };
#Some programs don't have nix packages available, so making use of Homebrew is needed, sadly there is also no way of installing home brew through nix
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
        "viscosity"
        "linearmouse"
        "altserver"
        "tailscale"
      ];
      enable = true;
      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
        upgrade = true;
      };
    };
#Network settings, plan to move these to their own module once I get wireguard setup
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
#Garbage collection for the Nix Store
    nix = {
      gc = {
        automatic = true;
        interval = {
          Hour = 48;
        };
        options = "-d";
      };
#Nix Store config, hard linking identical dependancies etc.
      settings = {
        auto-optimise-store = true;
        sandbox = true;
        allowed-users = [
          "carln"
        ];
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
      stateVersion = 4;
    };
#User specific settings, eventually plan to create the user account itself through Nix as well
    users = {
      users = {
        carln = {
          home = {
            _type = "override";
            content = /Users/carln;
            priority = 50;
          };
          name = "carln";
          shell = pkgs.zsh;
        };
      };
    };
  };
}
