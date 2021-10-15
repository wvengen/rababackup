# Remote Android Backup solution (rababackup)

An exploration of how to do backups on Android with Borg Backup.

_Work in Progress_

_Goal_: keeping backups of Android phones on a [Borg Backup](https://www.borgbackup.org/)
  server of your choice with a pleasant user experience.

Currently we assume that the phone is rooted (allows for more complete backups).

Ideally there would be a front-end like [OAndBackupX](https://github.com/machiav3lli/oandbackupx)
to create and restore backups.

See [APPROACHES](APPROACHES.md) for possible solutions. Right here the option I'm currently
pursuing is presented, which is running Borg Backup on the device, either with a modified
OAndBackupX or a custom app.

## Running Borg

Borg is a Python program, which is run on the phone. Luckily Termux has this working already,
we'll gather all dependencies in an archive to run it from within the app, so one doesn't need
to install Termux. See [borg-bin-termux](borg-bin-termux) for more information.

## Backing up

Ideally Borg works directly on the phone's filesystem, using its logic to determine which files
need to be stored. This is relatively easy.

This to investigate:

- Figure out what paths need to be backed up.

- Figure out how stable these paths are (same across Android versions?).

- Don't store cached/generated parts: dex, oat, tempfiles, cached files, ...


## Restoring

This is where things get a little more complicated.

- Are paths stable across Android versions? If not, we'll need some path translation part
  (e.g. using `borg export-tar`)

- APKs need to be installed:
  - first extract to a temporary location
  - install the app (look at F-Droid for different installation methods; also see OAndBackupX)
  - also test when the app has multiple apks or other components

- App data restore:
  - after the APK is installed
  - setting permissions and ownership (based on what Android chose as user/group)
  - restore SELinux context
  - investigate whether the location is stable

- User data restore: things in `/sdcard` not already backed up (and elsewhere??)


## App / front-end

As Borg Backup works with snapshots, it would make sense to present snapshots as a primary
interface for restoring, and then looking at what apps are available. As a secondary view,
the apps could be listed with relevant backups (but that needs some caching of what is
available in which snapshots) (similar to OAndBackupX).

See also the [steps OAndBackupX follows](OANDBACKUPX.md) when backing up and restoring.

