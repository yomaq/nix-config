{ config, lib, pkgs, inputs, ... }:
with lib;
{
  # I have to do this so I can import it into multiple modules, because if I import it directly to multiple modules... it breaks
  imports = [inputs.impermanence.nixosModules.impermanence];


  options.yomaq.impermanence = {
    backup = mkOption {
      type = types.str;
      default = "/persist/save";
      description = "The persistent directory to backup";
    };
    dontBackup = mkOption {
      type = types.str;
      default = "/persist";
      description = "The persistent directory to not backup";
    };
  };
  config = {
    yomaq.impermanence.backup = mkIf config.yomaq.disks.amReinstalling "/tmp";
  };
}