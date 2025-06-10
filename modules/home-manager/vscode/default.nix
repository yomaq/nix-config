{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.yomaq.vscode;
in
{
  options.yomaq.vscode = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom vscode module
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      package = pkgs.vscode;
      enable = true;
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      mutableExtensionsDir = false;
      extensions = [
        pkgs.vscode-extensions.dracula-theme.theme-dracula
        pkgs.vscode-extensions.bbenoist.nix
        pkgs.vscode-extensions.ms-python.python
        pkgs.vscode-extensions.ms-vscode-remote.remote-ssh
      ];
      userSettings = {
        "[nix]"."editor.tabSize" = 2;
        "workbench.colorTheme" = "Dracula";
        "git.confirmSync" = "false";
      };
    };
  };
}
