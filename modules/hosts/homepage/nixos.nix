{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.yomaq.homepage;
  yamlReadyList =
    attrs:
    lib.attrsets.mapAttrsToList (groupName: services: {
      ${groupName} = lib.attrsets.mapAttrsToList (serviceName: serviceAttrs: {
        ${serviceName} = serviceAttrs;
      }) services;
    }) attrs;
  formatWidgets =
    widgets:
    lib.attrsets.mapAttrsToList (widgetName: widgetAttrs: {
      ${widgetName} = widgetAttrs;
    }) widgets;
in
{
  options.yomaq.homepage = {
    enable = lib.mkEnableOption (lib.mdDoc "Homepage Dashboard");
    bookmarks = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Bookmarks for homepage dashboard";
    };
    services = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Service groups for homepage dashboard";
    };
    widgets = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Widgets for homepage dashboard";
    };
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Settings for homepage dashboard";
    };
    settingsLayout = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Layout configuration for homepage dashboard";
    };
  };
  options.yomaq.homepage.groups = {
    services = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Services to be added to the Services group";
    };
    bookmarks = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Bookmarks to be added to groups";
    };
  };
  config = lib.mkIf cfg.enable {
    services.homepage-dashboard = {
      settings = cfg.settings // {
        layout = cfg.settingsLayout;
      };
      widgets = formatWidgets cfg.widgets;
      services = yamlReadyList cfg.services;
      bookmarks = yamlReadyList cfg.bookmarks;
    };
    services.homepage-dashboard.package = pkgs.unstable.homepage-dashboard;
    age.secrets."homepage".file = (inputs.self + /secrets/homepage.age);
    services.homepage-dashboard.environmentFile = "${config.age.secrets."homepage".path}";

    yomaq.homepage = {
      services = {
        "Services" = cfg.groups.services;
      };
      bookmarks = {
      };
      settingsLayout.Services = {
        tab = "Services";
      };
    };
  };
}
