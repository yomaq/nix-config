{ inputs, config, lib, pkgs, ... }: {
  config = {


    
    dconf.settings."org/gnome/shell".disable-user-extensions = false;
    
    
    # gnome theme-ing
    gtk = {
        enable = true;

        iconTheme = {
        name = "purple";
        package = pkgs.fluent-icon-theme;
        roundedIcons = true;
        };
    };
  };
}