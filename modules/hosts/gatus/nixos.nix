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
    ### example of how to add a gatus monitor in another module for use on any host in the flake.
    # yomaq.gatus.endpoints = [{
    #   name = "gatus test test";
    #   group = "webapps";
    #   url = "https://${hostName}-${NAME}.${tailnetName}.ts.net/";
    #   interval = "5s";
    #   conditions = [
    #     "[CONNECTED] == true"
    #   ];
    # }];

    ### On the Gatus server itself, just set config.yomaq.gatus.enable = true;
    ### The gatus server will check all nixosConfigurations for all gatus config, and automatically update the server.
  };
}
