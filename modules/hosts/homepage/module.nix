{ config, lib, pkgs, inputs, modulesPath, ... }:
let
  listOfHosts = lib.attrNames inputs.self.nixosConfigurations;
  cfg = config.yomaq.homepage;

  convertAttrSetToList = attrSet: map (name: { "${name}" = attrSet."${name}"; }) (lib.attrNames attrSet);

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
  config = {
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
  };
}