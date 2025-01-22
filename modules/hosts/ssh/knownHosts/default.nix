{
  options,
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.ssh.knownHosts = {
    "green".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIcWzIPdRcEgS7EKXHL8IrLF1UKf52DwIv5oFtiMNZ6/";
    "green-initrd".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGNx39knO81AjtLTLMwuMeT58feKT1CFkYrCmT2p6SZ";

    "blue".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGKoF3ul1ezP+OnokU6uLIQ6/ztUcboQX7trOw1cHg4H";
    "blue-initrd".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHizEipg12TEKUZJjCq5exR/Ydpp6iL6gGHtQ5NCWobM";

    "azure".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP2G2qPq4NAu18EE0CB7Kfm5F3FIvphuzv13BlCXuKbu";
    "azure-initrd".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINPtserZFFxlpTCyiRPNx8KhQlSk8cJ5IUedP6isB1q5";

    "teal".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK7JriToIhfbruPxV0TJI9SF2nTKINmlsnSoyDdAVVoY";
    "teal-initrd".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBX5raO/z+XWBKjOU4JwGvquTMYSgxcg+tCFU3ok5s6H";

    "carob".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBLSY5QLMJ2LsNNT+PHeo7mA7Izr56evvOqjfFTfGvhz";

    "pearl".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHX2aVm/O7Zs0qWzhU1I2xNH8JNx6q1HTy50epYqEXBI";

    "smalt".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILR615VGZfPxDnK6dDumGUByl8n8ZT8hctQ0HzXplxPB";
    "smalt-initrd".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFk1pvG36S3ICyy70Ci3Y5b1/wOEvyfD2hkw6qLhC/LG";
  };
}
