{ options, config, lib, pkgs, ... }:

with lib;
let
  cfg = config.yomaq.vscode;
in
{
  options.yomaq.vscode = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable custom vscode module
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.vscode = {
      package = pkgs.vscode;
      enable = true;
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      mutableExtensionsDir = false;
      extensions = [
        pkgs.vscode-extensions.dracula-theme.theme-dracula
        pkgs.vscode-extensions.bbenoist.nix
        pkgs.vscode-extensions.github.copilot
        pkgs.vscode-extensions.ms-python.python
      ];
      userSettings = {
        "[nix]"."editor.tabSize" = 2;
        "workbench.colorTheme" = "Dracula";
        "git.confirmSync" = "false";
      };
    };
  };
}