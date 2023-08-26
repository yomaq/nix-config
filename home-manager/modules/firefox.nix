{ inputs, config, lib, pkgs, ... }: {
  config = {
    home = {
      packages = [
        pkgs.firefox
      ];
    };
    programs.firefox = {
        enable = true;
        profiles.carln = "carln";
        profiles.carln.IsDefault = true;
        profiles.carln = {
            extensions = [
                privacy-badger
            ];
        };
    };
  };
}
