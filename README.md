# Remote Android Backup solution (rababackup)

An exploration of how to do backups on Android with Borg Backup.

_Work in Progress_

_Goal_: keeping backups of Android phones on a [Borg Backup](https://www.borgbackup.org/)
  server of your choice with a pleasant user experience.

Ideally there would be a front-end like [OAndBackupX](https://github.com/machiav3lli/oandbackupx)
to create and restore backups.


## Approach 1. Plain backup to remote storage

To connect Borg and OAndBackupX, the idea is to use backup directly to an SFTP server.
With Android's Storage Access Framework (SAF) OAndBackupX can do that with the help of

- [rcx](https://github.com/x0b/rcx).

In this approach the backup is done directly to a remote server using RCX, and the
server runs Borg Backup.

One major blocker is that currently RCX doesn't support writing (yet).


### Approach 1a. Scripted prototype

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


### Approach 1b. Remote FUSE filesystem

The prototype isn't very user-friendly and has race-conditions. A better way could
be to write a FUSE filesystem that would allow OAndBackupX to interact with a
Borg Backup archive directly. Let's call this FUSE filesystem the _raba_ filesystem.

This filesystem would translate reading and writing to direct access to the Borg Backup
archive. Working with OAndBackupX would be transparent.

#### Implementation

When the _raba_ filesystem is mounted, the Borg Backup archive is mounted somewhere,
and the _raba_ filesystem exposes symlinks to get access to the files. This is read-only
access, and would make restoring backups work.

When a backup is written, the _raba_ filesystem unmounts the backup archive (required
to write to a Borg Backup archive) and waits until the backup is done. Then Borg Backup
will be run, after which the archive is mounted again.

Let's see how far we could get.


### Approach 1c. Adapting Borg Backup

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
(or air). But it is much more complex than the previous approaches.


## Approach 2. Running Borg on the phone

Borg Backup is meant to be used on the client-side, connecting to a remote server. If you
want to encrypt the backup so the server doesn't know the archive contents, this is the
only way.

Running Borg Backup on Android is not so straightforward. There are basically three options:

- running it within [Termux](https://termux.org/) ([borg issue](https://github.com/borgbackup/borg/issues/1155))
- getting it to work on [python-for-android](https://github.com/kivy/python-for-android) (I've got a prototype barely running)
- packaging compiled binaries in an Android app (e.g. the Termux package, I've got that working in ~20MB)


### Approach 2a. Termux scripts

One could install Termux and borg inside, then create a script to backup what you need.
You're on your own to restore data, though, and this needs some steps, like mentioned in
[this post](https://www.semipol.de/posts/2016/07/android-manually-restoring-apps-from-a-twrp-backup/).

See also [borgbackup_on_android](https://github.com/ravenschade/borgbackup_on_android).


### Approach 2b. OAndBackupX with tar streams

It would be great if OAndBackupX could not only backup to a filesystem, but also to Borg.
One idea would be to let OAndBackupX internally have the option to generate a tar output stream,
and pass that as standard input to a `borg import-tar` process. File restore could work with
`borg export-tar`.


### Approach 2c. OAndBackupX with borg

Another idea would be to let OAndBackupX compose a list of files, which Borg Backup could
backup or restore. A bonus would be that unchanged files may not need to be read. OAndBackupX
would still take care of preparing files before backup and after restore.

One issue could be that OAndBackupX perhaps copies files before they are backed up. If there
is a single `borg` invocation, all files need to be copied, requiring a lot more disk space.


### Approach 2d. Custom backup app

It's unclear whether approach 2c would fit well within OAndBackupX. If not, then a new
application would be necessary. This would also solve some issues where OAndBackupX and
Borg work slightly differently. It is some duplication of work, though, and needs to
be maintained.


### Notes on OAndBackupX with Borg

OAndBackupX stores different backups in different folders (see below). Borg has a single
file structure, and handles different versions internally.

    org.example.one
      2021-01-01
        app.apk
        data.tar.gz


OAndBackupX allows backing up apps one by one. Will these become separate backups in Borg?
Or do we better disable single-app backup, only allowing batches? Or is it ok to have one
backup with one app, after that a backup with another app, etc.? Or will each app get its
own archive, where OAndBackupX can then restore them all at once too?


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
