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
    ];
    userSettings = {
      "[nix]"."editor.tabSize" = 2;
    };
  };
}