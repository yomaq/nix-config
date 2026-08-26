{ pkgs, ... }:
let
  # Pinned so running this devshell on a fresh machine recreates the exact
  # same pi state as on this machine:
  #  - pi binary: numtide/llm-agents.nix at this revision (0.84.3)
  #  - extension: pi-web-access pinned to 0.25.0 (matches the lockfile in
  #    ~/.pi/agent/npm/package-lock.json)
  pi = "github:numtide/llm-agents.nix@4c7c50e9c7aab5a1fbc8d4e26d196a76fde00fc3";
  webAccess = "npm:pi-web-access@0.25.0";

  # Inline extension (never persisted to disk): points pi at the Ollama
  # OpenAI-compatible API, so no API key or auth.json entry is needed.
  ollamaProvider = pkgs.writeText "pi-ollama-provider.ts" ''
    import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

    export default function (pi: ExtensionAPI) {
      pi.registerProvider("ollama", {
        name: "Ollama (wsl)",
        baseUrl: "https://wsl-ollama.sable-chimaera.ts.net/v1",
        apiKey: "ollama",
        api: "openai-completions",
        models: [
          {
            id: "qwen3.8:27b",
            name: "Qwen3.8 27B (wsl-ollama)",
            reasoning: true,
            input: ["text", "image"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 32768,
            maxTokens: 8192,
          },
        ],
      });
    }
  '';

  # Idempotent, non-destructive bootstrap of the global pi state that
  # `pi install` does not manage. Written to ~/.pi (the default when
  # PI_CODING_AGENT_DIR and XDG_CONFIG_HOME are unset); existing values
  # are preserved, only missing ones are filled in.
  bootstrap = pkgs.writeText "pi-bootstrap.mjs" ''
    import fs from "node:fs";
    import os from "node:os";
    import path from "node:path";

    const setIfMissing = (file, mutate) => {
      let data = {};
      try {
        data = JSON.parse(fs.readFileSync(file, "utf8"));
      } catch {
        // missing file (fresh machine): start from an empty object
      }
      mutate(data);
      fs.mkdirSync(path.dirname(file), { recursive: true });
      fs.writeFileSync(file, JSON.stringify(data, null, 2) + "\n");
    };

    const home = os.homedir();

    // ~/.pi/agent/settings.json: theme (default is dark, but set it
    // explicitly so the state is identical); packages entry is added
    // by `pi install`.
    setIfMissing(path.join(home, ".pi", "agent", "settings.json"), (s) => {
      if (s.theme === undefined) s.theme = "dark";
    });

    // ~/.pi/web-search.json: SSRF allowlist for pi-web-access
    // (private IP of the local LLM host).
    setIfMissing(path.join(home, ".pi", "web-search.json"), (w) => {
      const range = "100.123.62.119/32";
      if (w.ssrf === undefined) w.ssrf = {};
      if (!Array.isArray(w.ssrf.allowRanges)) w.ssrf.allowRanges = [];
      if (!w.ssrf.allowRanges.includes(range)) w.ssrf.allowRanges.push(range);
    });
  '';
in
pkgs.mkShell {
  packages = [
    # pi's `install npm:<pkg>` shells out to `npm`, so it must be on PATH.
    pkgs.nodejs
  ];

  env = {
    # Search backend for the pi-web-access extension.
    SEARXNG_BASE_URL = "https://azure-searxng.sable-chimaera.ts.net";
  };

  shellHook = ''
    # 1) Install the pinned pi-web-access extension. This is the part that
    #    creates ~/.pi/agent/npm/ and the `packages` entry in
    #    ~/.pi/agent/settings.json on a fresh machine; re-running is a no-op.
    nix run ${pi}#pi -- install ${webAccess}

    # 2) Fill in any missing pieces of the global pi state (theme,
    #    web-search SSRF allowlist) without touching existing values.
    node ${bootstrap}

    # 3) Launch pi with the local Ollama provider and model pinned.
    nix run ${pi}#pi -- -e ${ollamaProvider} --model ollama/qwen3.8:27b
    exit $?
  '';
}
