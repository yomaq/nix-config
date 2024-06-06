{ config, lib, pkgs, inputs, modulesPath, ... }:
let
  cfg = config.yomaq.gatus;
  settingsFormat = pkgs.formats.yaml { };
  listOfHosts = lib.attrNames inputs.self.nixosConfigurations;
in
{
  options.yomaq.gatus = {
    enable = lib.mkEnableOption (lib.mdDoc "Gatus Dashboard");
    endpoints = lib.mkOption {
      inherit (settingsFormat) type;
      default = [];
    };
    externalEndpoints = lib.mkOption {
      inherit (settingsFormat) type;
      default = [];
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "https://azure-gatus.sable-chimaera.ts.net";
      description = "url for the gatus server";
    };
  };
  config = lib.mkIf cfg.enable {
    services.gatus = {
      settings = {
        endpoints = lib.mkMerge (map (hostname: lib.mkIf (inputs.self.nixosConfigurations."${hostname}".config.yomaq.gatus.endpoints!= [])
          inputs.self.nixosConfigurations."${hostname}".config.yomaq.gatus.endpoints
        ) listOfHosts);
        external-endpoints = lib.mkMerge (map (hostname: lib.mkIf (inputs.self.nixosConfigurations."${hostname}".config.yomaq.gatus.externalEndpoints!= [])
          inputs.self.nixosConfigurations."${hostname}".config.yomaq.gatus.externalEndpoints
        ) listOfHosts);
      };
    };
    ### example of how to add a gatus monitor in another module
    # yomaq.gatus.endpoints = [{
    #   name = "gatus test test";
    #   group = "webapps";
    #   url = config.yomaq.gatus.url;
    #   interval = "5s";
    #   conditions = [
    #     "[CONNECTED] == true"
    #   ];
    # }];
  };
}
