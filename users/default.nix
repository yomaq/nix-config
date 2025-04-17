{ lib, ... }:
## Import all modules inside this folder recursively.
## from: https://github.com/evanjs/nixos_cfg/blob/4bb5b0b84a221b25cf50853c12b9f66f0cad3ea4/config/new-modules/default.nix
let
  # Recursively constructs an attrset of a given folder, recursing on directories, value of attrs is the filetype
  getDir =
    dir:
    lib.mapAttrs (
      file: type: if type == "directory" then getDir "${dir}/${file}" else null
      # If you want to exclude recusing on directories (untested)
      # if type == "directory" then null else type
    ) (builtins.readDir dir);
  # Collects all files of a directory as a list of strings of paths
  files =
    dir:
    lib.collect lib.isString (
      lib.mapAttrsRecursive (path: type: lib.concatStringsSep "/" path) (getDir dir)
    );
  # Filters out directories that don't end with .nix or are this file, also makes the strings absolute
  validFiles =
    dir:
    map (file: ./. + "/${file}") (
      lib.filter (
        file:
        lib.hasSuffix "default.nix" file
        # Exclude this file
        && file != "default.nix"
        # how to exclude a path
        # && ! lib.hasPrefix "exclude/path/" file
        # how to exclude a group of files
        # && ! lib.hasSuffix "-ex.nix" file
      ) (files dir)
    );
in
{
  imports = validFiles ./.;
}
