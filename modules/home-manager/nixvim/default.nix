{
  ...
}:
{
  # imports = [ inputs.nixvim.homeManagerModules.nixvim ];
  # options.yomaq.nixvim = {
  #   enable =
  #     lib.mkOption {
  #       type = lib.types.bool;
  #       default = false;
  #       description = ''
  #         enable custom nixvim module
  #       '';
  #     };
  # };
  # config = lib.mkIf cfg.enable {
  #   programs.nixvim = {
  #     enable = true;

  #     opts = {
  #       number = true;
  #       shiftwidth = 2;
  #     };
  #     colorschemes.dracula.enable = true;
  #     plugins = {
  #       lightline.enable = true;
  #       nix.enable = true;
  #     };
  #   };
  # };
}
