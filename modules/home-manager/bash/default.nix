{
  config,
  lib,
  ...
}:
let
  cfg = config.yomaq.bash;
in
{
  imports = [ ];
  options.yomaq.bash = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom bash module
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      bash = {
        enable = true;
        enableCompletion = true;
        profileExtra = ''
          # Commands that should be applied only for interactive shells.
          [[ $- == *i* ]] || return

          HISTFILESIZE=100000
          HISTSIZE=10000

          shopt -s histappend
          shopt -s checkwinsize
          shopt -s extglob
          shopt -s globstar
          shopt -s checkjobs


          #defaults
          export EDITOR=vim

          #auto completion
          source <(kubectl completion bash)
          alias k=kubectl
          complete -o default -F __start_kubectl k
        '';
      };
    };
  };
}
