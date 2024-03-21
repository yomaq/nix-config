{ config, lib, pkgs, inputs, modulesPath, ... }:
let
  listOfHosts = lib.attrNames inputs.self.nixosConfigurations;
  cfg = config.yomaq.homepage.groups;
in
{

  config = {
    age.secrets."homepage".file = (inputs.self + /secrets/homepage.age);

    yomaq.homepage-dashboard = {
        environmentFile = "${config.age.secrets."homepage".path}";
        enable = true;
      };
    yomaq.homepage = {
      services = [
        # { favorites =  lib.mkMerge (map (hostname: lib.mkIf (inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.groups.services.favorites != null) 
        #     inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.groups.services.favorites) listOfHosts);}
        { utilities =  lib.mkMerge (map (hostname: lib.mkIf (inputs.self.nixosConfigurations."${hostname}".config.yomaq.homepage.groups.services.utilities != null) 
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
      };
    };
  };
}