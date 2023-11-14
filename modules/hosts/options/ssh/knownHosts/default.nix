{ options, config, lib, pkgs, ... }:
{
  programs.ssh.knownHosts = {
    # using the agenix key as the known host key for devices we unencrypt with initrd ssh
    "green".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA+JAQVPpnno4PNYWSoTIbpNTkJ8EZDPobKFv0oL7tpu";
    };
}