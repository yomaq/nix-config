{ config, lib, pkgs, inputs, modulesPath, ... }:
let
  cfg = config.yomaq.homepage;
  listOfHosts = lib.attrNames inputs.self.nixosConfigurations;
  mergeConfig = configKey: lib.mkMerge (map (hostname: lib.mkIf (inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage."${configKey}" != null) 
      inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage."${configKey}") listOfHosts);
in
{
  options.yomaq.homepage = {
    settings = lib.mkOption {
      default = null;
      type = lib.types.nullOr (lib.types.submodule {
          freeformType = (pkgs.formats.yaml { }).type;
      });
    };
    widgets = lib.mkOption {
      default = null;
      type = lib.types.nullOr (lib.types.listOf (lib.types.submodule {
        freeformType = (pkgs.formats.yaml { }).type;
      }));
    };
    services = lib.mkOption {
      default = null;
      type = lib.types.nullOr (lib.types.listOf (lib.types.submodule {
        freeformType = (pkgs.formats.yaml { }).type;
      }));
    };
    bookmarks = lib.mkOption {
      default = null;
      type = lib.types.nullOr (lib.types.listOf (lib.types.submodule {
        freeformType = (pkgs.formats.yaml { }).type;
      }));
    };
  };
  options.yomaq.homepage.groups = {
    services = {
      favorites =lib.mkOption {
        default = null;
        type = lib.types.nullOr (lib.types.listOf (lib.types.submodule {
          freeformType = (pkgs.formats.yaml { }).type;
        }));
      };
      utilities =lib.mkOption {
        default = null;
        type = lib.types.nullOr (lib.types.listOf (lib.types.submodule {
          freeformType = (pkgs.formats.yaml { }).type;
        }));
      };
    };
    bookmarks = {
      favorites =lib.mkOption {
        default = null;
        type = lib.types.nullOr (lib.types.listOf (lib.types.submodule {
          freeformType = (pkgs.formats.yaml { }).type;
        }));
      };
      utilities =lib.mkOption {
        default = null;
        type = lib.types.nullOr (lib.types.listOf (lib.types.submodule {
          freeformType = (pkgs.formats.yaml { }).type;
        }));
      };
    };
  };
  config = lib.mkIf config.yomaq.homepage-dashboard.enable {
    yomaq.homepage-dashboard = {
        listenPort = 3000;
        settings = mergeConfig "settings";
        widgets = mergeConfig "widgets";
        services = mergeConfig "services";
        bookmarks = mergeConfig "bookmarks";
    };
    services.homepage-dashboard.package = pkgs.unstable.homepage-dashboard;
    age.secrets."homepage".file = (inputs.self + /secrets/homepage.age);
    yomaq.homepage-dashboard.environmentFile = "${config.age.secrets."homepage".path}";



    #####
    ##### Service configuration
    #####


    yomaq.homepage = {
    ### Bookmark and service groups cannot have the same names.
    ### Empty lists will break the config
    ### Also add the layout for the group below.
      services = [
        { Services =  lib.mkMerge (map (hostname: lib.mkIf (inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.groups.services.utilities != null) 
            inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.groups.services.utilities) listOfHosts);}
      ];
      bookmarks = [
        # { favorites =  lib.mkMerge (map (hostname: lib.mkIf (inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.groups.bookmarks.favorites != null) 
        #     inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.groups.bookmarks.favorites) listOfHosts);}
        # { utilities =  lib.mkMerge (map (hostname: lib.mkIf (inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.groups.bookmarks.utilities != null) 
        #     inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.groups.bookmarks.utilities) listOfHosts);}
      ];
      widgets = [
        {datetime = {
            format = {
              timeStyle = "short";
            };
        };}
        {search = {
            provider = "brave";
            focus = true; # Optional, will set focus to the search bar on page load
            showSearchSuggestions = true; # Optional, will show search suggestions. Defaults to false
            target = "_blank"; # One of _self, _blank, _parent or _top
        };}
        {openmeteo = {
            label = "Okc"; # optional
            latitude =   "35.46756";
            longitude = "-97.51643";
            timezone = "America/Chicago"; # optional
            units = "Imperial"; # or "imperial"
            cache = 5; # Time in minutes to cache API responses, to stay within limits
            format = { # optional, Intl.NumberFormat options
              maximumFractionDigits = 1;
            };
        };}
      ];
    settings ={
        title = "{{HOMEPAGE_VAR_NAME}}";
        background = {
            blur = "sm"; # sm, "", md, xl... see https://tailwindcss.com/docs/backdrop-blur
            saturate = 50; # 0, 50, 100... see https://tailwindcss.com/docs/backdrop-saturate
            brightness = 50; # 0, 50, 75... see https://tailwindcss.com/docs/backdrop-brightness
            opacity = 50; # 0-100
        };
        color = "slate";
        theme = "dark"; # or light
        hideVersion = "true";
        useEqualHeights = true;



        layout = {
          Services = {
            tab = "Services";
          };
        };
      };
    };

  };
}