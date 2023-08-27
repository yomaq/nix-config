{ inputs, config, lib, pkgs, ... }: {
  imports = [
    inputs.nur.nixosModules.nur
  ];
  config = {
    nixpkgs.overlays = [inputs.nur.overlay];
    home.packages = [pkgs.firefox-unwrapped];
    programs.firefox = {
      package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
        extraPolicies = {
          CaptivePortal = false;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableTelemetry = true;
          DisableFirefoxAccounts = true;
          NoDefaultBookmarks = true;
          OfferToSaveLogins = false;
          OfferToSaveLoginsDefault = false;
          PasswordManagerEnabled = false;
          FirefoxHome = {
              Search = true;
              Pocket = false;
              Snippets = false;
              TopSites = false;
              Highlights = false;
          };
          UserMessaging = {
              ExtensionRecommendations = false;
              SkipOnboarding = true;
          };
        };
      };
      enable = true;
      profiles.default = {
        id = 0;
        name = "Default";
        isDefault = true;
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
            ublock-origin
            onepassword-password-manager
            maya-dark
            darkreader
        ];
        search = {
            force = true;
            default = "DuckDuckGo";
        };
        settings = {
            "general.smoothScroll" = true;
        };
      };
    };
  };
}