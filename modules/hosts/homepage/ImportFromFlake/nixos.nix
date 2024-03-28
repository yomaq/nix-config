{ config, lib, pkgs, inputs, modulesPath, ... }:
let
  cfg = config.yomaq.homepage;
  settingsFormat = pkgs.formats.yaml { };
  listOfHosts = lib.attrNames inputs.self.nixosConfigurations;
  mergeConfig = configKey: lib.mkMerge (map (hostname: lib.mkIf (inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage."${configKey}" != []) 
      inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage."${configKey}") listOfHosts);
  mergeServiceGroups = configKey: lib.mkMerge (map (hostname: lib.mkIf (inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.groups.services."${configKey}" != []) 
    inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.groups.services."${configKey}") listOfHosts);
  mergeBookmarksGroups = configKey: lib.mkMerge (map (hostname: lib.mkIf (inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.groups.bookmarks"${configKey}" != []) 
    inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.groups.bookmarks"${configKey}") listOfHosts);
in
{
  options.yomaq.homepage = {
    bookmarks = lib.mkOption {
      inherit (settingsFormat) type;
      default = [ ];
    };
    services = lib.mkOption {
      inherit (settingsFormat) type;
      default = [ ];
    };
    widgets = lib.mkOption {
      inherit (settingsFormat) type;
      default = [ ];
    };
    settings = lib.mkOption {
      inherit (settingsFormat) type;
      default = { };
    };
  };
  options.yomaq.homepage.groups = {
    services = {
      services =lib.mkOption {
        inherit (settingsFormat) type;
        default = [];
      };
    };
    bookmarks = {
      favorites =lib.mkOption {
        inherit (settingsFormat) type;
        default = [];
      };
    };
  };
  config = lib.mkIf config.yomaq.homepage-dashboard.enable {
    yomaq.homepage-dashboard = {
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
        { Services = mergeServiceGroups "services"; }
      ];
      bookmarks = [
        # { favorites = mergeServiceGroups "favorites"; }
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