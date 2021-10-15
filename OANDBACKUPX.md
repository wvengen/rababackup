# OAndBackupX process

What does OAndBackupX do when backing up and restoring data?
Looked at the source code of version 7.0.0.

## Backup

Source files: `BackupAction.kt`, `AppInfo.kt`, `AppMetaInfo.kt`, `BaseAppAction.kt`.
For the directories, see subsections below.

When data files are gathered, the following restrictions apply:
- exclude if source directory name contains `.gms.`, skip it to exclude Google's push notifications
- exclude directories named `cache`, `code_cache`, `lib` (can be disabled by preference to include cache)
- exclude files in the "root" directory of the app's data (but include subdirectories)

### APK

[`android.content.pm.ApplicationInfo#sourceDir`](https://developer.android.com/reference/android/content/pm/ApplicationInfo#sourceDir)

[`android.content.pm.ApplicationInfo#splitSourceDirs`](https://developer.android.com/reference/android/content/pm/ApplicationInfo#splitSourceDirs)

### Data

[`android.content.pm.ApplicationInfo#dataDir`](https://developer.android.com/reference/android/content/pm/ApplicationInfo#dataDir)

### Protected data

[`android.content.pm.ApplicationInfo#deviceProtectedDataDir`](https://developer.android.com/reference/android/content/pm/ApplicationInfo#deviceProtectedDataDir)

### External data

```kotlin
// Uses the context to get own external data directory
// e.g. /storage/emulated/0/Android/data/com.machiav3lli.backup/files
// Goes to the parent two times to the leave own directory
// e.g. /storage/emulated/0/Android/data
// Add the package name to the path assuming that if the name of dataDir does not equal the
// package name and has a prefix or a suffix to use it.
"${context.getExternalFilesDir(null)!!.parentFile!!.parentFile!!.absolutePath}${File.separator}$packageName"
```

### OBB files

```kotlin
// Uses the context to get own obb data directory
// e.g. /storage/emulated/0/Android/obb/com.machiav3lli.backup
// Goes to the parent two times to the leave own directory
// e.g. /storage/emulated/0/Android/obb
// Add the package name to the path assuming that if the name of dataDir does not equal the
// package name and has a prefix or a suffix to use it.
"${context.obbDir.parentFile!!.absolutePath}${File.separator}$packageName"
```

### Media files

```kotlin
// Uses the context to get own obb data directory
// e.g. /storage/emulated/0/Android/media/com.machiav3lli.backup
// Goes to the parent two times to the leave own directory
// e.g. /storage/emulated/0/Android/media
// Add the package name to the path assuming that if the name of dataDir does not equal the
// package name and has a prefix or a suffix to use it.
"${context.obbDir.parentFile!!.parentFile!!.absolutePath}${File.separator}media${File.separator}$packageName"
```


## Restore

Source files: `RestoreAppAction.kt`, `ShellHandler.kt`.
Happens in the following order.

### APK

1. Extract APK(s) in a staging directory (subdirectory of `context.getExternalFilesDir()`).
2. When _disable verification_ is enabled, run: `settings put global verifier_verify_adb_installs 0`
3. Install main APK: `cat "<app.apk>" | pm install -t -r -S <filesize_of_app>`
4. Install extra APKs: `cat "<app_n.apk>" | pm install -p <base_package_name> -t -r -S <filesize_of_app_n>`
5. When _disable verification_ is enabled, run: `settings put global verifier_verify_adb_installs 1`

Add `-g` to `pm install` when _restore all permissions_ is enabled.

Add `-d` to `pm install` when _allow downgrade_ is enabled.

### Data

Target dir is the same as the backup source path (see above).

1. `mkdir -p "<target_dir>"`
2. extract files in temporary directory (using `Files.createTempDirectory`)
3. wipe target directory, except paths excluded during backup
4. move all files to the target directory
5. Get ownership info of target dir using `ls -bdAlZ` -> _, _, _user_, _group_, _context_, ...
6. Apply ownership info to all extracted files (i.e. don't set it on files excluded during backup)
   run: `chown -R <user>:<group> <files>`
7. Apply context to all extracted files (ibid)
   if _context_ is `?` run: `restorecon -RF -v <target_dir>`
   otherwise run: `chcon -R -h -v <context> <target_dir>`

### Protected data

Same as Data.

### External data

Same as Data, but without setting ownership and context.

### OBB files

Same as Data, but without setting ownership and context.

### Media files

Same as Data, but without setting ownership and context.

