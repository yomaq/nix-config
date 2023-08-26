{ inputs, config, lib, pkgs, ... }: {
  config = {


    
    dconf.settings = {
        "org/gnome/shell" = {
          disable-user-extensions = false;

          # `gnome-extensions list` for a list
          enabled-extensions = [
            "burn-my-windows@schneegans.github.com"
            "caffeine@patapon.info"
            "unite@hardpixel.eu"
            "forge@jmmaranan.com"
            "space-bar@luchrioh"
            "just-perfection-desktop@just-perfection" 
            "user-theme@gnome-shell-extensions.gcampax.github.com" 
            "blur-my-shell@aunetx"
          ];
        };
        "org/gnome/shell/extensions/unite" = {
          hide-window-titlebars = "always";
        };
      };
    
    
    # gnome theme-ing
    home.packages = [
      pkgs.fluent-gtk-theme
      pkgs.fluent-icon-theme
    ];
    dconf.settings."org/gnome/shell/extensions/user-theme".name = "Fluent-Dark-compact";


    gtk = {
        enable = true;

        iconTheme = {
        name = "Fluent-Dark";
        package = pkgs.fluent-icon-theme;
        };
        theme = {
          name = "Fluent-Dark-compact";
          package = pkgs.graphite-gtk-theme;
        };
        gtk3.extraConfig = {
          Settings = ''
            gtk-application-prefer-dark-theme=1
          '';
        };

        gtk4.extraConfig = {
          Settings = ''
            gtk-application-prefer-dark-theme=1
          '';
        };
    };
    home.sessionVariables.GTK_THEME = "Fluent-Dark-compact";
  };
}