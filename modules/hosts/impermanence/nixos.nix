{
  config,
  lib,
  inputs,
  ...
}:
{
  # I have to do this so I can import it into multiple modules, because if I import it directly to multiple modules... it breaks
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  options.yomaq.impermanence = {
    backup = lib.mkOption {
      type = lib.types.str;
      default = "/persist/save";
      description = "The persistent directory to backup";
    };
    backupStorage = lib.mkOption {
      type = lib.types.str;
      default = "/storage/save";
      description = "The persistent directory to backup";
    };
    dontBackup = lib.mkOption {
      type = lib.types.str;
      default = "/persist";
      description = "The persistent directory to not backup";
    };
  };
  config = {
    yomaq.impermanence.backup = lib.mkIf config.yomaq.disks.amReinstalling "/tmp";
    yomaq.impermanence.backupStorage = lib.mkIf config.yomaq.disks.amReinstalling "/tmp";
  };
}
