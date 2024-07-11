{ pkgs, ... }: 
{ 
  env = {
    GREET = "Yomaq's Home Flake";
  };

  packages = with pkgs; [
  ];

  enterShell = ''
    echo $GREET
  ''; 

  scripts = {
    # remove nix system gernerations older than 7 days
    yo-clean.exec = ''
      sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d
    '';
    # garbage collect all unused nix store entries
    yo-gc.exec = ''
      sudo nix store gc --debug
      sudo nix-collect-garbage --delete-old
    '';
    # update nixos or nix-darwin from github
    yo-rb.exec = ''
      if [[ "$OSTYPE" == "darwin"* ]]; then \
          darwin-rebuild switch --flake github:yomaq/nix-config ;\
      elif [[ "$OSTYPE" == "linux-gnu"* ]]; then \
          sudo nixos-rebuild switch --option eval-cache false --flake github:yomaq/nix-config ;\
      else \
          echo "Unsupported OS" ;\
          exit 1 ;\
      fi
    '';
    # update nixos or nix-darwin from local flake
    yo-rbl.exec = ''
      if [[ "$OSTYPE" == "darwin"* ]]; then \
          darwin-rebuild switch --flake . ;\
      elif [[ "$OSTYPE" == "linux-gnu"* ]]; then \
          sudo nixos-rebuild switch --flake . ;\
      else \
          echo "Unsupported OS" ;\
          exit 1 ;\
      fi
    '';
    # update nixos on a remote machine
    yo-rbr.exec = ''
      if [ $# -eq 0 ]; then
          echo "Usage: $0 <hostname>"
          exit 1
      fi
      HOSTNAME=$1
      nixos-rebuild --use-substitutes --no-build-nix --build-host admin@$HOSTNAME --target-host admin@$HOSTNAME --use-remote-sudo switch --flake github:yomaq/nix-config#$HOSTNAME
    '';
    # update nixos on a remote machine using local flake
    yo-rbrl.exec = ''
      if [ $# -eq 0 ]; then
          echo "Usage: $0 <hostname>"
          exit 1
      fi
      HOSTNAME=$1
      nixos-rebuild --use-substitutes --no-build-nix --build-host admin@$HOSTNAME --target-host admin@$HOSTNAME --use-remote-sudo switch --flake .#$HOSTNAME
    '';
    yo-dry.exec = ''
      if [ $# -eq 0 ]; then
          echo "Usage: $0 <hostname>"
          exit 1
      fi
      HOSTNAME=$1
      nixos-rebuild --use-substitutes --no-build-nix --build-host admin@$HOSTNAME --target-host admin@$HOSTNAME --use-remote-sudo dry-activate --flake .#$HOSTNAME
    '';
    # install with nixos-anywhere for an encrypted host
    yo-install-encrypted.exec = ''
      ipaddress=$2
      hostname=$1

      eval $(op signin)

      # Create a temporary directory
      temp=$(mktemp -d)

      # Function to cleanup temporary directory on exit
      cleanup() {
        rm -rf "$temp"
      }
      trap cleanup EXIT

      # Create the directory where sshd expects to find the host keys
      install -d -m755 "$temp/etc/ssh/"

      # Obtain your private key for agenix from the password store and copy it to the temporary directory
      # also copy the key for the initrd shh server
      op read op:"//nix/$hostname/private key?ssh-format=openssh" > "$temp/etc/ssh/$hostname"


      # the initrd keys don't actually seem to work, but initrd secrets does need some kind of key, or it fails.
      # initrd ssh won't work, you will need to manually unlock encryption, then generate new keys.
      op read op:"//nix/initrd/private key?ssh-format=openssh" > "$temp/etc/ssh/initrd"
      # op read op:"//nix/$hostname-initrd/public key" > "$temp/etc/ssh/$hostname-initrd.pub"

      # Set the correct permissions so sshd will accept the key
      chmod 600 "$temp/etc/ssh/$hostname"
      chmod 600 "$temp/etc/ssh/initrd"

      # Install NixOS to the host system with our secrets and encription
      nix run github:numtide/nixos-anywhere -- --extra-files "$temp" --build-on-remote \
        --disk-encryption-keys /tmp/secret.key <(op read op://nix/$hostname/encryption) --flake .#$hostname root@$ipaddress
    '';
    yo-install.exec = ''
      ipaddress=$2
      hostname=$1

      # Install NixOS to the host system with our secrets and encription
      nix run github:numtide/nixos-anywhere  -- --flake .#$hostname root@$ipaddress
    '';
  };
}