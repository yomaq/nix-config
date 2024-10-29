{
  config,
  lib,
  pkgs,
  inputs,
  modulesPath,
  ...
}:
{
  imports = [
    # import custom modules
    inputs.self.nixosModules.yomaq
    inputs.self.nixosModules.pods
    # import users
    (inputs.self + /users/admin)
    inputs.nixos-wsl.nixosModules.default
  ];
  config = {
    networking.hostName = "wsl";
    system.stateVersion = "24.05";

    wsl.enable = true;
    wsl.defaultUser = "admin";
    # wsl.useWindowsDriver = true;


    # hardware.nvidia-container-toolkit.enable = true;
    # virtualisation.docker.enableOnBoot = true;

    # # Also enable OpenGL
    # hardware.opengl = {
    #   enable = true;
    #   driSupport = true;
    #   driSupport32Bit = true;
    # };

    # environment.systemPackages = with pkgs; [
    #   cudaPackages.cudatoolkit
    #   linuxPackages.nvidia_x11
    #   cudaPackages.cudnn
    # ];
    # # programs.zsh.shellInit = ''
    # #   export CUDA_PATH=${pkgs.cudaPackages.cudatoolkit}
    # #   export LD_LIBRARY_PATH=/usr/lib/wsl/lib:${pkgs.linuxPackages.nvidia_x11}/lib:${pkgs.ncurses5}/lib
    # #   export EXTRA_LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
    # #   export EXTRA_CCFLAGS="-I/usr/include"
    # # '';

    yomaq = {
      tailscale = {
        enable = true;
        extraUpFlags = [
          "--ssh=true"
          "--reset=true"
        ];
        useRoutingFeatures = "client";
        authKeyFile = null;
      };

      # docker.enable = true;
      # pods = {
      # };

      autoUpgrade.enable = true;
      primaryUser.users = [ "admin" ];
      timezone.central = true;
      suites = {
        basics.enable = true;
        foundation.enable = true;
      };
    };
  };
}
