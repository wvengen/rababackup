# Remote Android Backup solution (rababackup)

_Work in Progress_

_Goal_: keeping backups of Android phones on a server of your choice with open-source software.

Components:
- [Borg Backup](https://www.borgbackup.org/) to store backups efficiently.
- [OAndBackupX](https://github.com/machiav3lli/oandbackupx) to create and restore backups.

To connect the two, the idea is to use Android's Storage Access Framework (SAF),
allowing one to perform backups directly to a remote server. This is where

- [rcx](https://github.com/x0b/rcx) comes in.

Running Borg Backup on Android [requires running it in Termux](https://github.com/borgbackup/borg/issues/1155),
which brings some complexity. The current approach is to allow backup to the server
over SFTP, and then have Borg Backup handle the archiving from there.


## Step 0. Preconditions

1. Setup access from Android to a remote filesystem on the server using rcx.
2. Install Borg Backup on the server.


## Step 1. Prototype

### Backup
1. Run OAndBackupX storing files on the server.
2. When backup is done, a script gets files in a Borg Backup archive:
   - it shuffles files around to get archiving work correctly
   - it runs borg backup
   - it cleans up for next backup from the phone

### Restore
1. run a script to prepare restore
   - it extracts files from backup archive
   - it shuffles files around so OAndBackupX can make something of it
3. restore using OAndBackupX
4. run a script to cleanup files again for next backup


## Step 2. Integration

The prototype isn't very user-friendly and has race-conditions. A better way could
be to write a FUSE filesystem that would allow OAndBackupX to interact with a
Borg Backup archive directly. Let's call this FUSE filesystem the _raba_ filesystem.

This filesystem would translate reading and writing to direct access to the Borg Backup
archive. Working with OAndBackupX would be transparent.

### Implementation

When the _raba_ filesystem is mounted, the Borg Backup archive is mounted somewhere,
and the _raba_ filesystem exposes symlinks to get access to the files. This is read-only
access, and would make restoring backups work.

When a backup is written, the _raba_ filesystem unmounts the backup archive (required
to write to a Borg Backup archive) and waits until the backup is done. Then Borg Backup
will be run, after which the archive is mounted again.

Let's see how far we could get.


## On backup apps

Backing up and restoring on Android is not as straightforward as copying files
(see e.g. [here](https://forum.fairphone.com/t/backing-up-app-data-in-rooted-phones-whats-your-experience/38314/4)).
That's why we'd better use an existing app. We start here with OAndBackupX,
but perhaps later other apps could be supported, like
[OAndBackup](https://github.com/jensstein/oandbackup) and
[Seedvault](https://github.com/seedvault-app/seedvault).

