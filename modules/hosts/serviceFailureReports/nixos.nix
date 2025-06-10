{
  config,
  pkgs,
  lib,
  ...
}:
let
  createMonitoredService = _name: {
    onFailure = [ "yomaq-monitor@%i.service" ];
  };
  cfg = config.yomaq.monitorServices;
in
{
  options.yomaq.monitorServices = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        enable custom service monitoring
      '';
    };
    ollamaUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://wsl-ollama.sable-chimaera.ts.net";
      description = "URL for the Ollama API endpoint";
    };
    ollamaModel = lib.mkOption {
      type = lib.types.str;
      default = "llama3.1:8b";
      description = "Model to use for Ollama API requests";
    };
    ntfyBaseUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://azure-ntfy.sable-chimaera.ts.net";
      description = "Base URL for ntfy notifications";
    };
    n8nUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "URL for the n8n API endpoint. If set, logs will only be sent to n8n instead of Ollama/ntfy";
    };
    services = lib.mkOption {
      description = "A set of systemd services to monitor";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            priority = lib.mkOption {
              type = lib.types.str;
              default = "medium";
              description = "Priority level of the service (high/medium/low)";
            };
            topic = lib.mkOption {
              type = lib.types.str;
              default = "test";
              description = "Topic for ntfy notifications";
            };
          };
        }
      );
      default = { };
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services =
      {
        "yomaq-monitor@" = {
          description = "Monitors service failures, processes them and sends notifications";
          serviceConfig = {
            Type = "oneshot";
            ReadWritePaths = [ "/var/lib/systemd/yomaq-monitor" ];
            EnvironmentFile = "/var/lib/systemd/yomaq-monitor/%i.conf";
          };
          path = with pkgs; [
            jq
            curl
            systemd
            coreutils
          ];
          scriptArgs = "%I";
          script = ''
            SERVICE_NAME="$1"
            SERVICE_CLEAN=$(echo "$SERVICE_NAME" | sed 's/\.service$//' | sed 's|/|-|g')
            STATE_DIR="/var/lib/systemd/yomaq-monitor"
            STATE_FILE="$STATE_DIR/$SERVICE_CLEAN.state"
            ${
              if cfg.n8nUrl != "" then
                ''
                  N8N_URL="${cfg.n8nUrl}"
                ''
              else
                ''
                  OLLAMA_URL="${cfg.ollamaUrl}/api/generate"
                  OLLAMA_MODEL="${cfg.ollamaModel}"
                  NTFY_URL="${cfg.ntfyBaseUrl}/$SERVICE_TOPIC"
                ''
            }

            touch "$STATE_FILE" || {
              echo "ERROR: Failed to initialize state file" >&2
              exit 1
            }

            # current failure count
            if [ -s "$STATE_FILE" ]; then
              FAILURES=$(cat "$STATE_FILE" 2>/dev/null)
              # Validate that FAILURES is a number
              if ! [[ "$FAILURES" =~ ^[0-9]+$ ]]; then
                FAILURES=0
              fi
            else
              FAILURES=0
            fi

            # update failure count
            FAILURES=$((FAILURES + 1))
            echo "$FAILURES" > "$STATE_FILE"

            # Check if threshold reached
            if [ "$FAILURES" -ge "$SERVICE_RESTART_THRESHOLD" ]; then
              # Get journal entries
              journal_output=$(journalctl -u "$SERVICE_NAME" -n 25 --no-pager 2>/dev/null ||
                echo "Failed to fetch journal logs")
              journal_output=$(echo "$journal_output" | sed 's/[[:cntrl:]]/\\n/g')
              
              ${
                if cfg.n8nUrl != "" then
                  ''
                    # Create JSON payload for n8n
                    json_payload=$(jq -n \
                      --arg service "$SERVICE_CLEAN" \
                      --arg host "${config.networking.hostName}" \
                      --arg logs "$journal_output" \
                      --arg priority "$SERVICE_PRIORITY" \
                      '{service: $service, host: $host, logs: $logs, priority: $priority}')

                    # Send to n8n webhook
                    curl --max-time 30 -X POST \
                      -H "Content-Type: application/json" \
                      -d "$json_payload" \
                      "$N8N_URL" || echo "ERROR: Failed to send data to n8n" >&2
                  ''
                else
                  ''
                    # Send to ollama
                    prompt="Analyze these system logs and identify potential issues. Keep things short. Start with a VERY short summary of what the issue is, followed by 3 potential solutions. At the end of your message include the last 5 lines from the logs: $journal_output"
                    response=$(curl --max-time 30 \
                      -H 'Content-Type: application/json' \
                      "$OLLAMA_URL" \
                      -d "$(jq -n --arg model "$OLLAMA_MODEL" --arg prompt "$prompt" \
                      '{model: $model, prompt: $prompt, stream: false}')" 2>/dev/null ||
                      echo '{"response": "API request failed"}')

                    # Send notification
                    summary=$(echo "$response" | jq -r '.response' 2>/dev/null ||
                      echo "Failed to parse API response")
                    if [ -n "$summary" ]; then
                      curl --max-time 30 -X POST "$NTFY_URL" \
                        -H "Title: $SERVICE_CLEAN on "${config.networking.hostName}" failed" \
                        -d "$summary" || \
                        echo "ERROR: Failed to send notification" >&2
                    else
                      curl --max-time 30 -X POST "$NTFY_URL" \
                        -H "Title: Service Analysis Failed" \
                        -d "Analysis failed for $SERVICE_NAME" || \
                        echo "ERROR: Failed to send error notification" >&2
                    fi
                  ''
              }
              
              # Reset counter after sending notification
              echo 0 > "$STATE_FILE" || echo "ERROR: Failed to reset failure counter" >&2
            fi
            exit 0
          '';
        };
        # Monitored services
      }
      // builtins.listToAttrs (
        map (service: {
          name = service;
          value = createMonitoredService service;
        }) (builtins.attrNames cfg.services)
      );
    systemd.tmpfiles.rules =
      [
        "d /var/lib/systemd/yomaq-monitor 0755 root root -"
      ]
      ++ (lib.mapAttrsToList (
        service: cfg:
        "L+ /var/lib/systemd/yomaq-monitor/${service}.conf - - - - ${(pkgs.writeText "yomaqMonitor${service}.conf" ''
          SERVICE_PRIORITY=${cfg.priority}
          SERVICE_TOPIC=${cfg.topic}
          SERVICE_RESTART_THRESHOLD=${
            toString (
              let
                restartSetting = config.systemd.services.${service}.serviceConfig.Restart or "no";
                willRestartOnFailure = restartSetting == "always" || restartSetting == "on-failure";
              in
              if !willRestartOnFailure then
                1
              else
                (config.systemd.services.${service}.serviceConfig.StartLimitBurst or 5)
            )
          }
        '')}"
      ) cfg.services);
  };
}
