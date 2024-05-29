{ options, config, lib, pkgs, inputs, ... }:

let
  cfg = config.yomaq.healthcheckUrl;
in
{
  options.yomaq.healthcheckUrl = lib.mkOption {
    type = lib.types.submodule {
      freeformType = lib.types.attrs;
    };
    default = {};
    description = "A submodule for health check URLs.";
  };

  config = {
    yomaq.healthcheckUrl = {
      syncoid = {
        smalt = "https://azure-healthchecks.sable-chimaera.ts.net/ping/47dc1f57-6780-4246-8052-4bf5cb4bbddd";
        teal = "https://azure-healthchecks.sable-chimaera.ts.net/ping/54c781e4-7f67-42ec-89de-16f98ba55d9f";
        carob = "https://azure-healthchecks.sable-chimaera.ts.net/ping/73e0cf2b-5ccc-40cc-8f9e-badbe053e5b4";
        azure = "https://azure-healthchecks.sable-chimaera.ts.net/ping/53d019ba-c0f5-4354-8335-98eca466e15d";
      };
    };
  };
}
