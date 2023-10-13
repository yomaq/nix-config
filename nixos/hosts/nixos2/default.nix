{ config, lib, pkgs, ... }:
  # written by chatgpt
   let
     dirPath = "./";
     importModules = dirPath: builtins.foldl' (moduleList: moduleName: if moduleName != "default.nix" then moduleList // { moduleName = import dirPath + "/" + moduleName; } else moduleList) [] (builtins.readDir dirPath);
   in
   {
     imports = importModules dirPath;
   }