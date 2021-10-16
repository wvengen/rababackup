# Borg Android Archive

On backup, Borg Backup is invoked directly on the filesystem with a specification
of the files to be backed up. The order is important, so that the restore process
functions correctly. This file describes the layout of a backup.

All archives _must_ contain a contents file as the first file in the archive.

## Contents file

The first file to be backed up _must_ be the contents file, which lists information
about the contents of the backup, as well as some other metadata, in JSON format.
You might recognize OAndBackupX's backup properties in `applications`, this is
intentional.

Applications creating a borg android archive _must_ include all of the keys below

This file _may_ contain extra fields at all levels, which applications _should_
be able to handle (i.e. ignore those fields). An archive _should_ be able to
be restored ignoring all fields not listed here.

Note that all fields are required and _must_ be present, unless marked as "(optional)".

```js
{
  // Version of the contents file, must be "0.1" for now
  // This will change to "1.0" on first release of an app. Follows semver.
  "fileVersion": "0.1",

  // Name and version of the application that generated this archive. (optional)
  "appLabel": "OAndBackupX",
  "appId": "com.machiav3lli.backup",
  "appVersionName": "7.0.0",
  "appVersionCode": 7000,

  // Applications backed up in the archive. (optional)
  "applications": [
    // One entry for each backed up application.
    {
      //// Fields present in OAndBackupX 7.0.0

      // Date when the application was backed up
      "backupDate": "2021-01-01T00:00:00.000",
      // Architecture of the app
      "cpuArch": "x86",
      // Name and version of the backed up application
      "packageLabel": "Foo",
      "packageName": "org.example.foo",
      "versionName": "1.0.0",
      "versionCode": 1000,
      // Whether this application was a system application when backed up.
      "isSystem": false,
      // Profile id (user)
      "profileId": 0,
      // Which components are present in the archive
      //   true = present
      //   false = absent
      //   null = treat als false (could be used to indicate the app has no such data)
      "hasApk": true,
      "hasAppData": true,
      "hasDevicesProtectedData": true,
      "hasExternalData": true,
      "hasMediaData": true,
      "hasObbData": true,
      // Original locations of the APKs (optional)
      "sourceDir": "/data/app/org.example.foo-12345678abc==/base.apk",
      "splitSourceDirs": ["data/app/org.example.foo-123456789abc==/extra_1.apk"],

      //// Fields specific to Borg android archives

      // Where to find files in the archive.
      // Note that paths should not start with a '/'. Directory paths may end with a '/'.
      // When "hasApk", "hasAppData", etc. is not true,
      // the corresponding archivePath key is (optional).
      "archivePaths": {
        // Path of the main APK in the archive
        "apk": "data/app/org.example.foo-123456789abc==/base.apk",
        // Paths of any split APKs in the archive (if none, the empty array)
        "apkSplits": ["data/app/org.example.foo-123456789abc==/extra_1.apk"],
        // Paths of data directories in the archive
        "data": "data/data/org.example.foo/",
        "devicesProtectedData": "data/data_de/org.example.foo/",
        "externalData": "storage/emulated/0/Android/data/org.example.foo/",
        "mediaData": "storage/emulated/0/Android/media/org.example.foo/",
        "obbData": "storage/emulated/0/Android/obb/org.example.foo/",
    }
  ]
}
```

## Applications

Application data comes after the contents file.

For each application, the APKs _must_ come first. If there are multiple APKs, the
base APK _must_ be the first, then any additional (split) APKs.

Application data follows. There are four kinds of application data:
- Data
- Protected data
- External data
- OBB files

The list above shows the preferred order, which an archiving app _may_ follow, but
restoring apps _should_ allow any order. All data files of a certain kind _must_
come after each other, without any of the other kinds of application data in between,
so that a restoring app _may_ assume that when a file of a different kind appears in
the archive, no more files of the previous kind will appear in the archive.

The restoring app can recognize which files in the archive are related to which kind
of data by matching a file's path with the `archivePaths` in the contents file. If
the file path matches one of the `archivePaths`, it knows what kind of data it is.

Apps working with a borg android archive _must_ be able to handle files in the archive
unrelated to the applications (i.e. does not match any of the `archivePaths`),
which _should_ be ignored. They can appear in any order, but only after the contents
file. They _should_ not be in between different files of the same kind.


## Other

At this moment, there is no other data. It is open for future expansion. Restoring
apps _must_ ignore any other data.

