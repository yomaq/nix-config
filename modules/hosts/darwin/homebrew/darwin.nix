{
  ...
}:
{
  # options.yomaq.homebrew = {
  #   enable = lib.mkOption {
  #     type = lib.types.bool;
  #     default = false;
  #     description = '''';
  #   };
  # };
  # config = lib.mkIf cfg.enable {
  #   homebrew = {
  #     brewPrefix = "/opt/homebrew/bin";
  #     enable = true;
  #     onActivation = {
  #       autoUpdate = true;
  #       cleanup = "zap";
  #       upgrade = true;
  #     };
  #     casks = [
  #       "moonlight"
  #       "raycast"
  #       "arc"
  #       "linearmouse"
  #       "spotify"
  #       "nextcloud"
  #       "brave-browser"
  #       "zen-browser"
  #       "obsidian"
  #     ];
  #     taps = [ "pulumi/tap" ];
  #     brews = [
  #       "mas"
  #       "pulumi"
  #       "pulumi/tap/crd2pulumi"
  #       "pulumi/tap/kube2pulumi"
  #     ];
  #   };
  # };
}
