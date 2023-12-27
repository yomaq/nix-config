{ options, config, lib, pkgs, ... }:
{
  programs.ssh.knownHosts = {
    "green".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICWw4+s+Og4ASHmpP5s03O+mww5y1aPa9fE1rZHP1KDD";
    "green-initrd".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXJChTqiVIusv+GZ65vK8Uq9f4e4UDgaD3b2AEH6xh1";

    "blue".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEhFFEFJ3EhgPqvwG6cFBIRJzNmE2c/owqJ0afPGOplt";
    "blue-initrd".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOknfDLAOkOmZUHByJQEWzwdOJbj+SKoOTGEP+Es0glS";

    "azure".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJyHQ6+BRqbiqsK50g5mwkhDHUbh0KVkA6W32UDqV9OD";
    "azure-initrd".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFww5QBVekBnv+NMzRK6L+MIS8XrE6UMVK1xSUv/cHds";

    "teal".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK7JriToIhfbruPxV0TJI9SF2nTKINmlsnSoyDdAVVoY";
    "teal-initrd".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBX5raO/z+XWBKjOU4JwGvquTMYSgxcg+tCFU3ok5s6H";
    };
}