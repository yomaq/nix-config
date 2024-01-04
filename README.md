Nix flake with the following features:

* Ensures a clean system on every reboot by wiping root (rolling back an empty zfs snapshot), while [preserving](https://github.com/nix-community/impermanence) specified files across reboots.
* The files that are designated to persist are all stored in a single location, simplifying the process of creating backups that only include important files.
* The installation of NixOS is made convenient and consistent through [declarative partitioning of disks](https://github.com/nix-community/disko/tree/master), and [a single install ssh command](https://github.com/nix-community/nixos-anywhere/tree/main) ( + additional setups if encrypted).
* The flake manages the entire system, including [secrets](https://github.com/ryantm/agenix/tree/main).
* The flake is designed to be modular, making it easy to add to, and ensuring that all host outputs, whether NixOS or MacOS, look as similar as possible.
* All NixOS systems are set to automatically check for updates every hour, keeping all hosts in sync and identical as possible.



<details>
  <summary>Build on NixOS</summary>

**Install a host that already has configuration:**

* boot the host into a nixos installer, and set the root password
* complete the following steps on a different x86_64 machine with nix installed, and signed into 1password
* run the script `utilities/nixos-anywhere/remote-install-encrypt.sh HOSTNAME IPADDRESS-OF-TARGET`
* let the install complete, then unlock the drive manually (initrd ssh will not work yet)
* hit * to ignore the error after unlocking if needed
* remake the /etc/ssh/initrd host key and rebuild the nixos configuration
* now upon rebooting, the system will have normal behavior and initrd ssh will function



**Update the system(rebuild)**:  
```
nixos-rebuild switch --flake github:yomaq/nix-config
```
</details>

<details>
  <summary>NixDarwin (MacOS) Setup</summary>

Install Nix on MacOS:
https://nixos.org/download.html#nix-install-macos
(not tested, but likely better https://zero-to-nix.com/concepts/nix-installer)

```
sh <(curl -L https://nixos.org/nix/install)
```
Install Nix-Darwin (use all defaults):
https://github.com/LnL7/nix-darwin
```
nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
./result/bin/darwin-installer
```
Enable Flakes:
https://nixos.wiki/wiki/Flakes
```
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```
Install Homebrew: https://docs.brew.sh/Installation
(a couple packages are installed through homebrew as the nixpkgs appear broke on mac even tho they say it is supported)
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```
Get the flake
```
git clone https://github.com/yomaq/nix-config.git
cd nix-config
```
Remove the old nix.conf 
```
sudo rm -f /etc/nix/nix.conf
```
Change computer name to match config
```
sudo scutil --set HostName midnight
```
***Repeat the following step each time you build new updates***

Build Darwin
```
darwin-rebuild switch --flake .
```
Or to build without cloning
```
darwin-rebuild switch --flake github:yomaq/nix-config
```
</details>


<details>
  <summary>ToDo</summary>

* Create a module to automatically backup every NixOS machine's /presist/save directories to a signle NixOS nas
* Detail new device setup
* Setup WSL ideally with the option to have nix configured GUI applications as well
* Create Sunshine NixOS module for remote desktop
* Work on module to declare non-NixOS vms in NixOS similar to KubeVirt
* Build a stripped down Template for getting started
* Decide how to manage a kubernetes cluster alongside my nix hosts


</details>