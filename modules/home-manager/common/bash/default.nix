{ inputs, config, lib, pkgs, outputs, ... }: {
  config = {
    programs = {
      bash = {
        enable = true;
        enableCompletion = true;
        initExtra = "[ -f $HOME/.bashrc2 ] && . $HOME/.bashrc2";
      };
    };
  };
}