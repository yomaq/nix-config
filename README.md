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
***Repeat the following step each time you pull new updates***

Build Darwin
```
darwin-rebuild switch --flake .
```
