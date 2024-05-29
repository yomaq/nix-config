{ options, config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.yomaq.ntfy;
in
{
  options.yomaq.ntfy = {
    ntfyUrl = mkOption {
      type = types.str;
      default = "";
      description = "The base URL for NTFY notifications.";
    };

    defaultTopic = mkOption {
      type = types.str;
      default = "";
      description = "The default topic for NTFY notifications.";
    };

    defaultPriority = mkOption {
      type = types.str;
      default = "";
      description = "The default priority level for NTFY notifications.";
    };
  };

  config = {
    yomaq.ntfy = {
      ntfyUrl = "https://azure-ntfy.sable-chimaera.ts.net/";
      defaultTopic = "ntfy";
      defaultPriority = "p:3";
    };
  };
}

# example:
# "curl -H ${config.yomaq.ntfy.defaultPriority} -d "message goes here" ${config.yomaq.ntfy.ntfyUrl}${config.yomaq.ntfy.defaultTopic}"