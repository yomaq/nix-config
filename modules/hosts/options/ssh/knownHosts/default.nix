{ options, config, lib, pkgs, ... }:
{
  programs.ssh.knownHosts = {
    "green".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICWw4+s+Og4ASHmpP5s03O+mww5y1aPa9fE1rZHP1KDD";
    "green-initrd".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXJChTqiVIusv+GZ65vK8Uq9f4e4UDgaD3b2AEH6xh1";
    };
}