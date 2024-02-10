{ config, lib, pkgs, inputs,  ... }:
{
  networking = {
    bridges.br0.interfaces = [ "eno2" ]; # Replace enp42s0 with the name of your physical interface
    interfaces.br0 = {};
    defaultGateway = "10.150.10.1"; # The IP address of your default gateway
    nameservers = [ "10.150.10.1" ]; # List of DNS servers
  };   

  containers.devcontainer = {
    hostBridge = "br0";
    autoStart = true;

    #everythi under config is just normal nixos configuration options, like you have for the host
    config = { config, pkgs, ... }: {
      system.stateVersion = "23.11";

      networking = {
        firewall = {
          enable = true;
          allowedTCPPorts = [ ];
        };
        # Use systemd-resolved inside the container
        # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
        useHostResolvConf = mkForce false;
      };
      services.resolved.enable = true;


    environment.systemPackages = with pkgs; [
        cowsay
      ];
    };
  };
}