{ pkgs, inputs, ... }:

let
  hostnamesList = builtins.attrNames inputs.self.nixosConfigurations;
  hostnamesString = builtins.concatStringsSep " " hostnamesList;
in

### I don't use pkgs._1password because I don't use it on macos, and I want the script to work on both

pkgs.writeShellScriptBin "initrd-unlock" ''

  if [ "$1" = "--up" ]; then
      hostnames="${hostnamesString}"
      # Iterate over each hostname
      for hostname in $hostnames; do
      # Ping the host
      ping -c 1 "$hostname" > /dev/null 2>&1

      # Check if the ping was successful
      if [ $? -eq 0 ]; then
          echo "$hostname is up"
      else
          echo "Could not reach $hostname"
      fi
      done
  else

      # Check if any arguments were provided
      if [ $# -eq 0 ]; then
      # If no arguments were provided, use all nixos hosts
      hostnames="${hostnamesString}"
      else
      # If arguments were provided, use them as the hostnames
      hostnames="$@"
      fi

      # Iterate over each hostname
      for hostname in $hostnames; do
          # Ping the host
          ping -c 1 "$hostname-initrd" > /dev/null 2>&1

          # Check if the ping was successful
          if [ $? -eq 0 ]; then

              #sign into 1password and get the secret
              eval $(op signin)
              password=$(op read op://nix/$hostname/encryption)

${pkgs.toybox}/bin/timeout 5s ssh -T root@$hostname-initrd <<EOF
$password
EOF
              echo "unlock sent"
          else
              echo "Could not reach $hostname-initrd"
          fi
      done
  fi
''
