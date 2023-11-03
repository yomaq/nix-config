{ inputs, config, lib, pkgs, outputs, ... }: {
 config = {
   programs = {
     tmux = {
       enable = true;
       shell = lib.mkIf (pkgs ? zsh) "\${pkgs.zsh}/bin/zsh"
                lib.mkIf (!(pkgs ? zsh)) "\${pkgs.bash}/bin/bash";
     };
   };
 };
}
