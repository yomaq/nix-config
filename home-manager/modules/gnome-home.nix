{ inputs, config, lib, pkgs, ... }: {
  config = {

### To configure Gnome, the documentation is poor.
### First open a terminal and run "dconf watch /" and then manually make the change in gnome you are wanting to set.
### Use the output in the terminal to tell you what information to put here.
### Example "dconf watch /" output:
###
###       /org/gnome/desktop/wm/keybindings/close
###         '<Super>q'
###
### Would be written as:
###
###    dconf.settings = {
###      "org/gnome/desktop/wm/keybindings" = {
###        close = [ "<Super>q" ];
###     };
###
### I found this page useful in learning how to set configurations:
### https://hoverbear.org/blog/declarative-gnome-configuration-in-nixos/





### Keyboard Shortcuts
    # Edit default gnome keyboard shortcuts:
    dconf.settings = {
      "org/gnome/desktop/wm/keybindings" = {
        close = [ "<Super>q" ];
        screensaver = ["<Alt><Super>l"];
      };
    # Custom keyboard shorcuts. Needs both to be told that the custom exists, and then below to be told what the custom is.
      # Tell it that the custom exists here, follow its example of "custom0", "custom1" etc.
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        ];
      };
      # Define the custom options here
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
          binding = "<Alt><Super>Return";
          command = "alacritty";
          name = "alacritty"; 
      };
    };


### Configure general Gnome settings here
    dconf.settings."org/gnome/desktop/interface".enable-hot-corners = false;

    


### I have not learned how to install packages from multiple locations within the same file, so everything gets install here, and then configured down below.
    home.packages = with pkgs; [
      # gnome extensions
      gnome.gnome-tweaks
      gnomeExtensions.unite
      gnomeExtensions.caffeine
      gnomeExtensions.blur-my-shell
      gnomeExtensions.burn-my-windows
      gnomeExtensions.space-bar 
      gnomeExtensions.forge
      gnomeExtensions.appindicator
      gnomeExtensions.rounded-window-corners
      gnomeExtensions.tailscale-status
      # gnome themes
      fluent-gtk-theme
      fluent-icon-theme
      volantes-cursors
      moka-icon-theme
      (graphite-gtk-theme.override {
        themeVariants = ["default"]; 
        tweaks = ["rimless" "nord" "darker"];
        })
      ];


### Configure Gnome Extensions
    # Enable specific Gnome extensions
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
            "user-theme@gnome-shell-extensions.gcampax.github.com" 
            "blur-my-shell@aunetx"
            "rounded-window-corners@yilozt"
            "tailscale-status@maxgallup.github.com"
          ];
        };
    # Configure the extensions settings
        "org/gnome/shell/extensions/unite" = {
          hide-window-titlebars = "always";
        };
        "org/gnome/shell/extensions/caffeine" = {
          enable-fullscreen = false;
        };
        "org/gnome/shell/extensions/rounded-window-corners" = {
          skip-libadwaita-app = false;
        };
        "org/gnome/shell/extensions/forge" = {
          window-gap-hidden-on-single = true;
          focus-border-toggle = false;
        };
      };
    



### Set gnome themes after installing them above
    dconf.settings."org/gnome/shell/extensions/user-theme".name = "Graphite-Dark-nord";
    home.sessionVariables.GTK_THEME = "Graphite-Dark-nord";
    gtk = {
        enable = true;

        iconTheme = {
        name = "Moka";
        package = pkgs.fluent-icon-theme;
        };
        cursorTheme = {
          name = "volantes_light_cursors";
           package = pkgs.volantes-cursors;
        };
        theme = {
          name = "Graphite-Dark-nord";
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
  };
}