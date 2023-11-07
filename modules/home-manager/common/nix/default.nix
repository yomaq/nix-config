{ inputs, lib, config, pkgs, ... }: {
  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
    # fix for home manager bug
  manual.manpages.enable = false;
}