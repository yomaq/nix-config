{ pkgs, ... }:
pkgs.mkShell {
  buildInputs = [
    pkgs._1password-cli
    pkgs.nixfmt-rfc-style
    pkgs.bash-completion
  ];

  shellHook = ''
    export GREET="Yomaq's Homelab"
    echo $GREET

    # only needed if installing nixos
    eval $(op signin)

    yo-clean() {
      sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d
    }

    yo-gc() {
      sudo nix store gc --debug
      sudo nix-collect-garbage --delete-old
    }

    yo-rb() {
      if [[ "$OSTYPE" == "darwin"* ]]; then
        darwin-rebuild switch --flake github:yomaq/nix-config
      elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo nixos-rebuild switch --option eval-cache false --flake github:yomaq/nix-config
      else
        echo "Unsupported OS"
        exit 1
      fi
    }

    yo-rbl() {
      if [[ "$OSTYPE" == "darwin"* ]]; then
        darwin-rebuild switch --flake .
      elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo nixos-rebuild switch --flake .
      else
        echo "Unsupported OS"
        exit 1
      fi
    }

    yo-rbr() {
      if [ $# -eq 0 ]; then
        echo "Usage: $0 <hostname>"
        exit 1
      fi
      HOSTNAME=$1
      nixos-rebuild --use-substitutes --no-build-nix --build-host admin@$HOSTNAME --target-host admin@$HOSTNAME --use-remote-sudo switch --flake github:yomaq/nix-config#$HOSTNAME
    }

    yo-rbrl() {
      if [ $# -eq 0 ]; then
        echo "Usage: $0 <hostname>"
        exit 1
      fi
      HOSTNAME=$1
      nixos-rebuild --use-substitutes --no-build-nix --build-host admin@$HOSTNAME --target-host admin@$HOSTNAME --use-remote-sudo switch --flake .#$HOSTNAME
    }

    yo-rbrl-ip() {
      if [ $# -eq 0 ]; then
        echo "Usage: $0 <hostname> <ip>"
        exit 1
      fi
      HOSTNAME=$1
      IP=$2
      nixos-rebuild --use-substitutes --no-build-nix --build-host admin@$IP --target-host admin@$IP --use-remote-sudo switch --flake .#$HOSTNAME
    }

    yo-dry() {
      if [ $# -eq 0 ]; then
        echo "Usage: $0 <hostname>"
        exit 1
      fi
      HOSTNAME=$1
      nixos-rebuild --use-substitutes --no-build-nix --build-host admin@$HOSTNAME --target-host admin@$HOSTNAME --use-remote-sudo dry-activate --flake .#$HOSTNAME
    }

    #these are untested within nix-shell

    yo-install-encrypted() {
      ipaddress=$2
      hostname=$1
      eval $(op signin)
      temp=$(mktemp -d)
      cleanup() {
        rm -rf "$temp"
      }
      trap cleanup EXIT
      install -d -m755 "$temp/etc/ssh/"
      op read op:"//nix/$hostname/private key?ssh-format=openssh" > "$temp/etc/ssh/$hostname"
      op read op:"//nix/initrd/private key?ssh-format=openssh" > "$temp/etc/ssh/initrd"
      chmod 600 "$temp/etc/ssh/$hostname"
      chmod 600 "$temp/etc/ssh/initrd"
      nix run github:nix-community/nixos-anywhere -- --extra-files "$temp" --build-on remote \
        --generate-hardware-config nixos-generate-config "$(git rev-parse --show-toplevel)/hosts/$hostname/hardware-configuration.nix" \
        --disk-encryption-keys /tmp/secret.key <(op read op://nix/$hostname/encryption) --flake .#$hostname root@$ipaddress
    }

    yo-install() {
      ipaddress=$2
      hostname=$1
      nix run github:nix-community/nixos-anywhere -- --flake .#$hostname root@$ipaddress
    }
  '';
}
