{ inputs, ... }@flakeContext:
{ config, lib, pkgs, ... }: {
  config = {
    services = {
      yabai = {
        enable = true;
        config = {
          focus_follows_mouse = "autoraise";
          mouse_follows_focus = "off";
          mouse_modifier = "fn";
          window_placement    = "first_child";
          window_opacity      = "on";
          active_window_opacity = 1.0;
          normal_window_opacity = 0.9;
          top_padding         = 20;
          bottom_padding      = 10;
          left_padding        = 10;
          right_padding       = 10;
          window_gap          = 10;
        };
      };
    };
  };
}
