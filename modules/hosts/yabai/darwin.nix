{
  config,
  lib,
  ...
}:
let
  cfg = config.yomaq.yabai;
in
{
  options.yomaq.yabai = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom yabai module
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      #config for Yabai Window Manager, really basic config
      yabai = {
        enable = true;
        extraConfig = ''
          yabai -m config focus_follows_mouse          on
          yabai -m config window_placement             second_child
          yabai -m config window_opacity               on
          yabai -m config active_window_opacity        1.0
          yabai -m config normal_window_opacity        0.90
          yabai -m config auto_balance                 off
          yabai -m config mouse_modifier               cmd
          yabai -m config mouse_action1                move
          yabai -m config mouse_action2                resize
          yabai -m config mouse_drop_action            swap

          yabai -m config layout                       bsp
          yabai -m config top_padding                  8
          yabai -m config bottom_padding               8
          yabai -m config left_padding                 8
          yabai -m config right_padding                8
          yabai -m config window_gap                   8
          #yabai -m rule --add app=""                  manage=off
        '';
      };
      #config for skhd keyboard shortcuts for Yabai Window Manager.
      skhd = {
        enable = true;
        skhdConfig = ''
          shift + cmd - left    : yabai -m window --warp west
          shift + cmd - down    : yabai -m window --warp south
          shift + cmd - up      : yabai -m window --warp north
          shift + cmd - right   : yabai -m window --warp east
          shift + cmd - s       : yabai -m window --toggle split
        '';
      };
    };
  };
}
