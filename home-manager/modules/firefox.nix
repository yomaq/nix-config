{ inputs, config, lib, pkgs, ... }: {
  imports = [
    inputs.nur.nixosModules.nur
  ];
  config = {
    nixpkgs = {
        # You can add overlays here
        overlays = [
        inputs.nur.overlay
        ];
    };
    programs.firefox = {
      enable = true;
      profiles.default = {
        id = 0;
        name = "Default";
        isDefault = true;
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
            ublock-origin
            onepassword-password-manager
            bypass-paywalls-clean
        ];
      };
    };
  };
}
