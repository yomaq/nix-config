# just is a command runner, Justfile is very similar to Makefile, but simpler.

############################################################################
#
#  Nix commands related to the local machine
#
############################################################################

default:
  just --list

# Update the flake
update:
  nix flake update

# remove nix system gernerations older than 7 days
clean:
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

# garbage collect all unused nix store entries
gc:
  sudo nix store gc --debug
  sudo nix-collect-garbage --delete-old

# update nixos or nix-darwin from github
rb:
    if [[ "$OSTYPE" == "darwin"* ]]; then \
        darwin-rebuild switch --flake github:yomaq/nix-config ;\
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then \
        sudo nixos-rebuild switch --flake github:yomaq/nix-config ;\
    else \
        echo "Unsupported OS" ;\
        exit 1 ;\
    fi

# update nixos or nix-darwin from local flake
rbl:
    if [[ "$OSTYPE" == "darwin"* ]]; then \
        darwin-rebuild switch --flake . ;\
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then \
        sudo nixos-rebuild switch --flake . ;\
    else \
        echo "Unsupported OS" ;\
        exit 1 ;\
    fi

# update nixos on a remote machine
rbr host:
    nixos-rebuild  --use-substitutes --no-build-nix --build-host admin@{{host}} --target-host admin@{{host}} --use-remote-sudo switch --flake github:yomaq/nix-config#{{host}}
# update nixos on a remote machine using local flake
rbrl host:
    nixos-rebuild  --use-substitutes --no-build-nix --build-host admin@{{host}} --target-host admin@{{host}} --use-remote-sudo switch --flake .#{{host}}

############################################################################

# run nixos-anywhere with encryption
anywhere host ip:
    /Utilities/nixos-anywhere/remote-install-encrypt.sh {{host}} {{ip}}
# run nixos-anywhere without encryption
anywhere-unencrypted host ip:
    /Utilities/nixos-anywhere/remote-install.sh {{host}} {{ip}}
    