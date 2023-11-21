{ pkgs, ... }:

pkgs.writeShellScriptBin "initrd-unlock" ''

#provide host name
hostname=$1

# Ping the host
ping -c 1 "$hostname-initrd" > /dev/null 2>&1

# Check if the ping was successful
if [ $? -eq 0 ]; then

    #sign into 1password and get the secret
    eval $(op signin)
    password=$(op read op://nix/$hostname/encryption)

    ssh root@$hostname-initrd "$password"
    echo "unlock sent"

    sleep 5

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
''