{ inputs, lib, config, pkgs, ... }: {

  imports = [
  ];
  home.file.onePassword = {
    enable = true;
    target = "(~/.config/1Password/ssh/agent.toml";
    text = ''
      [[ssh-keys]]
      vault = "ssh"
    '';
  };
}