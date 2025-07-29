[![Nixos](https://img.shields.io/badge/NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white)](https://nixos.org) 
[![Static Badge](https://img.shields.io/badge/Tailscale-Tailscale?style=for-the-badge&logo=Tailscale&logoColor=white&labelColor=black&color=black)](https://tailscale.com)

![Name](https://github.com/yomaq/nix-config/actions/workflows/UpdateFlakeLock.yml/badge.svg)

# Nix Flake 

Flake for my personal desktop and self-hosted services.  
Attempting to view the Flake and its nixos hosts as a single logical unit, rather than trying to manage a collection of multiple computers.  

# Features

### Selfhosting

* Homelab/selfhosting focus with multiple docker and nixos container modules for various servers and services.
* Programmatically configured [Dashboard](https://github.com/gethomepage/homepage) that automatically expands as new hosts are added to the flake. Dashboard monitors host status, the current Nix Flake revision installed on each system, and the current revision on Gitlab.
* Programmatically configured uptime monitoring with [Gatus](https://github.com/TwiN/gatus), no matter which host a new service is deployed on, the Gatus server will automatically update its configuration to include the new service - Homepage dashboard also does the same with links to all current services automatically.
* Programmatically configured notifications and monitoring for failed Nixos updates and zfs backups, server and service downtime etc with [Ntfy](https://github.com/binwiederhier/ntfy) and [Gatus](https://github.com/TwiN/gatus).
* Tailscale modules for general VPN access, initrd ssh access, docker and nixos container configuration etc.
* All Flake host networking is heavily reliant on Tailscale, meaning automatic HTTPS certificates for all services, automatic DNS records, controlled Zero Trust access between all devices, no open ports required on any device. Additionally, no reliance on LAN for networking, so I can move any server to any network without any additional configuration required. Tailscale ACL is configured with Pulumi [here](https://github.com/yomaq/Tailscale-ACL).

### Installation and Updates

* The installation of NixOS is made convenient and consistent through [declarative partitioning of disks](https://github.com/nix-community/disko/tree/master), and [a single install ssh command](https://github.com/nix-community/nixos-anywhere/tree/main).
* Github Actions automatically updates the flake.lock weekly and run basic checks on the updates.
* All NixOS systems are set to automatically check for updates every hour, keeping all hosts in sync and identical as possible.

### Backups, File Management and Secrets
* Ensures a clean system on every reboot by wiping root (rolling back an empty zfs snapshot), while [preserving](https://github.com/nix-community/impermanence) specified files across reboots.
* The files that are designated to persist are all stored in a single location, enabling automated backups that only include important files.
* Backup server which automatically schedules new backup tasks as additional hosts are added to the flake by default.
* The flake manages the entire system, including [secrets](https://github.com/ryantm/agenix/tree/main).

### Flake design

* (New in-progress) A single `inventory.nix` file where all non-hardware device specific configuration happens. This is useful for clarity and readibility, but more importantly it allows all hosts to be "aware" of all other hosts and their configurations.
* All custom modules are joined together into a couple of Flake outputs, which are then **ALL** imported into the host in bulk.
* Custom modules all have options and are disabled by default. They must be enabled with `config.yomaq.moduleName.enable = true`
* Host modules (in [/modules/hosts](https://github.com/yomaq/nix-config/tree/main/modules)) that Nixos and Darwin can share are kept as identical as possible. Module options are shared between them in a `default.nix` file, while config implementations that differ will be in `nixos.nix` or `darwin.nix` respectively.
* All modules are automatically imported into their Flake Outputs without the need to manually list them all. You can simply drop in a new file in /modules/hosts or /modules/home-manager etc, and it will be automatically imported into the correct Flake Output.
* User accounts, similar to host modules, are configured with `darwin.nix` and`nixos.nix` files to keep configuration as consistent as possible (for all non home-manager user config).
* User specific config is kept clean and easy to read in the `/users` directory and are included on a system with `config.yomaq.users.enableUsers = [ list of users ];`

## Host Status Dashboard
Using the git revision of the flake, you can easily see which hosts are out of date.

![Homepage Dashboard](./Utilities/images/dashboard.png)



<details>
  <summary>Build on NixOS</summary>

**Install a host that already has configuration:**

* boot the host into a nixos installer (installer-iso ouput will build a nixos installer iso that is pre-loaded with a tailscale key to auto join the installer to your tailnet for easy remote installations), and set the root password (already set for installer-iso).
* complete the following steps on a different x86_64 machine with nix installed, and sign into 1password
* run the script `utilities/nixos-anywhere/remote-install-encrypt.sh HOSTNAME IPADDRESS-OF-TARGET`



**Update the system(rebuild)**:  
```
nixos-rebuild switch --flake github:yomaq/nix-config
```
</details>

<details>
  <summary>NixDarwin (MacOS) Setup</summary>

Install Nix on MacOS:
```
curl -sSf -L https://install.lix.systems/lix | sh -s -- install
```

Install Homebrew: https://docs.brew.sh/Installation
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```

Build Darwin for the first time (replace `midnight` with the correct hostname)
```
nix run nix-darwin -- switch --flake github:yomaq/nix-config#midnight
```
***Repeat the following to update***

```
darwin-rebuild switch --flake github:yomaq/nix-config
```
</details>


<details>
  <summary>ToDo</summary>

* Add a self hosted nix store cache server.
* Move docker containers to Quadlet.
* Adjust flake design to use an `inventory.nix` file, similar to clan.lol, this will remove the need for a single host to build the configuration of other hosts for modules like `gatus` and `homepage`.
* Microvms, possibly migrate some nixos-containers to microvms.


</details>
