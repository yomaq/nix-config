{ pkgs, ... }:
pkgs.mkShell {
  packages = [];
  env = {
    ANTHROPIC_BASE_URL = "https://wsl-ollama.sable-chimaera.ts.net";
  };
  shellHook = ''
    ${pkgs.claude-code}/bin/claude --model devstral-small-2
    exit $?
  '';
}
