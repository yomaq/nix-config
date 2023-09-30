{ inputs, config, lib, pkgs, ... }: {
  imports = [
  ];

  programs.vscode = {
    package = pkgs.vscode;
    enable = true;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    mutableExtensionsDir = false;
    extensions = [
      pkgs.vscode-extensions.dracula-theme.theme-dracula
      pkgs.vscode-extensions.bbenoist.nix
    ];
    userSettings = {
      "[nix]"."editor.tabSize" = 2;
      "workbench.colorTheme" = "Dracula";
      "git.confirmSync" = "false";
    };
  };
}