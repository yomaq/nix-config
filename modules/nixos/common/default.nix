{ lib, ... }:

## Import all default.nix modules within all neighbouring directories.
## from: https://github.com/evanjs/nixos_cfg/blob/4bb5b0b84a221b25cf50853c12b9f66f0cad3ea4/config/new-modules/default.nix

# with lib;
# let
#   getDir = dir: mapAttrs
#     (file: type:
#       if type == "directory" then getDir "${dir}/${file}" else null
#     )
#     (builtins.readDir dir);

#   files = dir: collect isString (mapAttrsRecursive (path: type: concatStringsSep "/" path) (getDir dir));

#   validFiles = dir: map
#     (file: ./. + "/${file}")
#     (filter
#       (file: hasSuffix "default.nix" file)
#       (files dir));

# in
{
  imports = [
    ./core/disko
    ./core/impermanance
  ];
}