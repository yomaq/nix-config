{ config, lib, pkgs, inputs, modulesPath, ... }:
let
  listOfHosts = lib.attrNames inputs.self.nixosConfigurations;
  cfg = config.yomaq.homepage;
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
      settings = lib.mkMerge (map (hostname: lib.mkIf (inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.settings != null) 
            inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.settings) listOfHosts);
      widgets = lib.mkMerge (map (hostname: lib.mkIf (inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.widgets != null) 
            inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.widgets) listOfHosts);
      services = lib.mkMerge (map (hostname: lib.mkIf (inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.services != null) 
            inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.services) listOfHosts);
      bookmarks = lib.mkMerge (map (hostname: lib.mkIf (inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.bookmarks != null) 
            inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.bookmarks) listOfHosts);
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