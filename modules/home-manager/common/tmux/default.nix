{ inputs, config, lib, pkgs, outputs, ... }: {
 config = {
   programs = {
     tmux = {
       enable = true;
       shell = if pkgs ? zsh then "${pkgs.zsh}/bin/zsh" else "${pkgs.bash}/bin/bash";
     };
   };
 };
}
