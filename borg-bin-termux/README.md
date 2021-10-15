As Borg runs in Termux, it is possible to combine the files from Termux packages
to obtain a runnable Borg binary to use on Android. This could be used from within
an Android application to run Borg.

The script [build-archives.sh](build-archives.sh) downloads the latest packages,
selects the relevant files, and creates archives that can be unpacked on Android.
Make sure to adapt the variable `ARCHS` in the script to your needs.

The package includes `borg`, `ssh` and `ssh-keygen`.

TODO show how to run, including unpacking both `borg-common.tgz` and `borg-<arch>.tgz`,
as well as setting `LD_LIBRARY_PATH` and `PYTHONPATH`/`PYTHONHOME`.

Possibilities to reduce size (currently 8MB common + 7MB i686):
- remove more unused Python modules
- replace `openssh` by a smaller alternative

