{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.yomaq.nvidia;
in
{
  options.yomaq.nvidia = {
    enable = lib.mkEnableOption (
      lib.mdDoc "Nvidia/Cuda Config. Docker containers must be ran with --device=nvidia.com/gpu=all etc"
    );
    wsl = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        if the system is wsl
      '';
    };
  };
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia.open = true;
    })
    (lib.mkIf (cfg.enable && cfg.wsl) {
      # https://github.com/nix-community/NixOS-WSL/issues/454
      environment.sessionVariables = {
        CUDA_PATH = "${pkgs.cudatoolkit}";
        EXTRA_LDFLAGS = "-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";
        EXTRA_CCFLAGS = "-I/usr/include";
        LD_LIBRARY_PATH = [
          "/usr/lib/wsl/lib"
          "${pkgs.linuxPackages.nvidia_x11}/lib"
          "${pkgs.ncurses5}/lib"
          # "/run/opengl-driver/lib"
        ];
        MESA_D3D12_DEFAULT_ADAPTER_NAME = "Nvidia";
      };
    })
    (lib.mkIf (cfg.enable && config.virtualisation.docker.enable) {
      # https://github.com/nix-community/NixOS-WSL/issues/578
      # containers must be run with "--device=nvidia.com/gpu=all"
      hardware.nvidia-container-toolkit = {
        enable = true;
        mount-nvidia-executables = lib.mkIf cfg.wsl false;
      };

      systemd.services = {
        nvidia-cdi-generator = lib.mkIf cfg.wsl {
          description = "Generate nvidia cdi";
          wantedBy = [ "docker.service" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.nvidia-docker}/bin/nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml --nvidia-ctk-path=${pkgs.nvidia-container-toolkit}/bin/nvidia-ctk";
          };
        };
      };

      virtualisation.docker = lib.mkIf cfg.wsl {
        daemon.settings.features.cdi = true;
        daemon.settings.cdi-spec-dirs = [ "/etc/cdi" ];
      };
    })
  ];
}
