Nix flake trying to focus on:

* Wiping root on every reboot for a clean system, while to [maintaining](https://github.com/nix-community/impermanence) specified files across boots.
* Making installing NixOS convenient and consistent. [Partitioning disks declaritavely](https://github.com/nix-community/disko/tree/master), and installing NixOS with [a single ssh command](https://github.com/nix-community/nixos-anywhere/tree/main).
* Managing the entire system including [secrets](https://github.com/ryantm/agenix/tree/main)  through the flake.
* Conveniently modularizing the flake so that it is easy to add to, and all host outputs whether NixOS or MacOS look as similar as possible.
* Making it possible to deploy configured systems with services and containers that start on their own upon the system's first boot allowing for full system configuration without ever signing into or otherwise pushing commands to the system.
* Automatically updating every system to the flake hourly, keeping all hosts in sync and identical as possible.


<details>
  <summary>Build on NixOS</summary>
Select the hostname to select the config

```
nixos-rebuild switch --flake github:yomaq/nix-config#HOSTNAME
```
</details>

<details>
  <summary>NixDarwin (MacOS) Setup</summary>

Install Nix on MacOS:
https://nixos.org/download.html#nix-install-macos

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

* Detail nixOS install + new device setup
* Setup WSL ideally with the option to have nix configured GUI applications as well
* Create Sunshine NixOS module for remote desktop
* Work on module to declare non-NixOS vms in NixOS similar to KubeVirt
* Build a stripped down Template for getting started
* Decide how to manage a kubernetes cluster alongside my nix hosts
* Setup Nix Hydra to automatically test new configurations before deploying
* Setup nixDarwin to auto update?


</details>