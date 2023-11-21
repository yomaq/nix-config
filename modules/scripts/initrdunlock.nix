{ pkgs, inputs, ... }:

let
    hostnamesList = builtins.attrNames inputs.self.nixosConfigurations;
    hostnamesString = builtins.concatStringsSep " " hostnamesList;
in


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

            echo -n "$password" | ssh -T root@$hostname-initrd > /dev/null
            echo "unlock sent"

            sleep 8

            ping -c 1 "$hostname-initrd" > /dev/null 2>&1

            # Check if the initrd sshd server has closed
            if [ $? -eq 0 ]; then
                echo "Initrd sshd server still open, unlock may have failed."
            else
                echo "Successfully unlocked"
            fi
        else
            echo "Could not reach $hostname-initrd"
        fi
    done
fi
''
