{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.yomaq.gatus;

  isServiceEnabled =
    path: hostConfig:
    let
      segments = lib.splitString "." path;
    in
    lib.attrByPath segments false hostConfig == true;
in
{
  options.yomaq.gatus = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Gatus configuration";
    };
    tailnetName = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "my-tailnet";
      description = "Global tailnet name";
    };
    endpoints = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              path = lib.mkOption {
                type = lib.types.str;
                example = "pods.dufs.enable";
                default = "pods.gatus.enable";
                description = "Path to check in the inventory";
              };
              config = lib.mkOption {
                type = lib.types.attrsOf lib.types.anything;
                default = { };
                description = "Standard gatus endpoint config";
                example = {
                  group = "webapps";
                  interval = "5m";
                  conditions = [ "[STATUS] == 200" ];
                };
              };
            };
          }
        )
      );
      default = { };
      description = "Gatus internal endpoint configurations";
    };

    externalEndpoints = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              path = lib.mkOption {
                type = lib.types.str;
                example = "pods.gatus.enable";
                default = "pods.gatus.enable";
                description = "Path to check in the inventory";
              };
              config = lib.mkOption {
                type = lib.types.attrsOf lib.types.anything;
                default = { };
                description = "standard gatus external endpoint config";
                example = {
                  group = "backup";
                };
              };
            };
          }
        )
      );
      default = { };
      description = "Gatus external endpoint configurations";
    };
  };

  config = lib.mkIf cfg.enable {
    services.gatus.settings.endpoints = lib.concatLists (
      lib.mapAttrsToList (
        serviceName: endpointCfg:
        let
          # Find hosts with this service enabled using lib.attrByPath
          serviceHosts = lib.filterAttrs (
            hostName: hostConfig: isServiceEnabled endpointCfg.path hostConfig
          ) config.inventory.hosts;
        in
        lib.mapAttrsToList (
          hostName: _:
          (
            endpointCfg.config
            // {

              name = "${hostName}-${serviceName}";
              url = "https://${hostName}-${serviceName}.${cfg.tailnetName}.ts.net";
            }
          )
        ) serviceHosts
      ) cfg.endpoints
    );

    services.gatus.settings.external-endpoints = lib.concatLists (
      lib.mapAttrsToList (
        serviceName: endpointCfg:
        let
          serviceHosts = lib.filterAttrs (
            hostName: hostConfig: isServiceEnabled endpointCfg.path hostConfig
          ) config.inventory.hosts;
        in
        lib.mapAttrsToList (
          hostName: _:
          (
            endpointCfg.config
            // {
              name = "${hostName}-${serviceName}";
              token = "${hostName}";
            }
          )
        ) serviceHosts
      ) cfg.externalEndpoints
    );
  };
}
