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


## Approach 1. Scripted prototype

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


## Approach 2. Remote FUSE filesystem

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


## Approach 3. Adapting Borg Backup

Another approach would be to adapt Borg Backup.
Currently [`borg serve`](https://borgbackup.readthedocs.io/en/stable/usage/serve.html) needs
a full-fledged borg client, which is hard to do on Android (without using Termux). It may be
possible to create a lightweight protocol that would run borg on the server-side, while
communicating about files, checksums and metadata with the client, and uploading (and perhaps
even downloading) files when necessary.

Then OAndBackupX could be adapted to support using this lightweight protocol (perhaps working on
[StorageFile](https://github.com/machiav3lli/oandbackupx/blob/5da37ac5a0b46535b2ed6a331ea845e29ad9ff98/app/src/main/java/com/machiav3lli/backup/items/StorageFile.kt)
plus some preferences could be enough).

The benefit if this approach is that only changed files need to be transferred over the wire
(or air). But it is probably more complex than the previous approaches.


## On backup apps

Backing up and restoring on Android is not as straightforward as copying files
(see e.g. [here](https://forum.fairphone.com/t/backing-up-app-data-in-rooted-phones-whats-your-experience/38314/4)).
That's why we'd better use an existing app. We start here with OAndBackupX,
but perhaps later other apps could be supported, like
[OAndBackup](https://github.com/jensstein/oandbackup) and
[Seedvault](https://github.com/seedvault-app/seedvault).

## On remote file access

This uses Android's Storage Access Framework (SAF).
- Currently [rcx](https://github.com/x0b/rcx) has some support, but it is too early to use (writing doesn't work yet).
- [saf-ftp](https://github.com/xdavidwu/saf-sftp) is a prototype, only supports reading.
- [FileManagerUtils](https://github.com/RikyIsola/FileManagerUtils) has a documents provider, not seen by OAndBackupX.
