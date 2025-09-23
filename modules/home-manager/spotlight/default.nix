{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.yomaq.spotlight-links;
in
{
  options.yomaq.spotlight-links = {
    enable = lib.mkEnableOption "Spotlight links for nix apps";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isDarwin) {
    home.activation.linkNixApps = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        APPS_DIR="$HOME/Applications/Nix-Apps"
        NIXAPPS=$(readlink -f "$HOME/.nix-profile/Applications")
        
        mkdir -p "$APPS_DIR"
        rm -rf "$APPS_DIR"/*
        
        for app_source in "$NIXAPPS"/*; do
          target="$APPS_DIR/$(basename "$app_source")"
          mkdir -p "$target/Contents"
          
          [[ -f "$app_source/Contents/Info.plist" ]] && 
            cp -f "$app_source/Contents/Info.plist" "$target/Contents/"
          
          if [[ -d "$app_source/Contents/Resources" ]]; then
            mkdir -p "$target/Contents/Resources"
            find "$app_source/Contents/Resources" -name "*.icns" -exec cp -f {} "$target/Contents/Resources/" \;
          fi
          
          [[ -d "$app_source/Contents/MacOS" ]] && 
            ln -sfn "$app_source/Contents/MacOS" "$target/Contents/MacOS"
          
          for dir in "$app_source/Contents"/*; do
            [[ -d "$dir" ]] || continue
            case "$(basename "$dir")" in
              Info.plist|Resources|MacOS) ;;
              *) ln -sfn "$dir" "$target/Contents/$(basename "$dir")" ;;
            esac
          done
        done

      echo "Linked nix applications to $APPS_DIR for spotlight"
    '';
  };
}
