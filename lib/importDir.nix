{ lib }:
# Import all matching .nix files from a directory recursively.
# example:
#   importDir { dir = ./.; }                                            # Import all .nix files
#   importDir { dir = ./.; pattern = "default.nix"; }                   # Import only default.nix files
#   importDir { dir = ./.; exclude = [ "old/" "test.nix" ]; }           # Exclude patterns (prefix/suffix)
#   importDir { dir = ./.; excludeExact = [ "nixos.nix" ]; }            # Exclude exact filenames
#   importDir { dir = ./.; exclude = [ "darwin.nix" ]; excludeExact = [ "default.nix" ]; } # Combine both

dir:
{
  pattern ? ".nix",
  exclude ? [ ],
  excludeExact ? [ ],
}:

let
  inherit (lib)
    filter
    hasSuffix
    hasPrefix
    removePrefix
    ;

  allFiles = lib.filesystem.listFilesRecursive dir;
  dirStr = toString dir;
  toRelative = file: removePrefix "${dirStr}/" (toString file);
in
filter (
  file:
  let
    relPath = toRelative file;
  in
  hasSuffix pattern relPath
  && relPath != "default.nix"
  && !(lib.any (pat: hasPrefix pat relPath || hasSuffix pat relPath) exclude)
  && !(lib.elem relPath excludeExact)
) allFiles
