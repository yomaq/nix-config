{ config, lib, pkgs, ... }: {
  config = {
    programs = {
#Generally avoid installing generic packages in darwin rather than homeManager, however zsh paths are broken without enabling it in nixDarwin as well
      zsh = {
        enable = true;
      };
    };
  };
}