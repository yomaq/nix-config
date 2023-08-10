{ inputs, ... }@flakeContext:
{ config, lib, pkgs, ... }: {
  config = {
    services = {
      yabai = {
        enable = true;
        config = {
          layout = "bsp";
          focus_follows_mouse = "autoraise";
          mouse_follows_focus = "off";
          mouse_modifier = "tab ";
          window_placement    = "second_child";
          window_opacity      = "on";
          active_window_opacity = 1.0;
          normal_window_opacity = 0.9;
          top_padding         = 5;
          bottom_padding      = 5;
          left_padding        = 5;
          right_padding       = 5;
          window_gap          = 5;
          mouse_drop_action = "swap"; 
        };
      };
      skhd = {
        enable = true;
        skhdConfig = ''
          shift + cmd - left : yabai -m window --warp west
          shift + cmd - down : yabai -m window --warp south
          shift + cmd - up : yabai -m window --warp north
          shift + cmd - right : yabai -m window --warp east
          shift + cmd - s : yabai -m window --toggle split
        '';
      };
    };
  };
}
