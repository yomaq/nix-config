gradually moving all zfs related modules to be here rather than be in host specific folders.

## declarative, reproducible disk setup
Disko modules will be setup (currently handled in the hosts folder) to commonly configure the disks on all nixOS machines, and automatically create datasets for use with impermancence

## impermanence with zfs
The root parition on all nixOS hosts is rolled back to a blank snapshot. Persisted datasets are created and mounted at /Persist and /PersistSave where the impermancence module is used to backup all required files to. **The zpool/PersistSave dataset becomes a single place that holds ALL files that should be saved, and ONLY files that have been specified to be saved.**

## zfs snapshots and backups with Sanoid/Syncoid
These two modules automatically create zfs snapshots of the zpool/persistSave datasets on all nixos systems, THEN backup those snapshots to a backup server where the snapshots are held for longer. The job of syncing the files to the backup server is completely handled by the server, and no tasks related to syncing are scheduled on the source computers.
Ssh keys in this case are not handled by nix, but by the tailnet 









# TODO 
currently services.syncoid.enable is enabled by default on all hosts in the syncoid module, when I change from using common modules to using suites, this should move to a suite and should be disabled by default here.