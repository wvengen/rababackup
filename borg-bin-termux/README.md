As Borg runs in Termux, it is possible to combine the files from Termux packages
to obtain a runnable Borg binary to use on Android. This could be used from within
an Android application to run Borg.

The script [build-archives.sh](build-archives.sh) downloads the latest packages,
selects the relevant files, and creates archives that can be unpacked on Android.
Make sure to adapt the variable `ARCHS` in the script to your needs.

The package includes `borg`, `ssh` and `ssh-keygen`.

Extract both the borg-common archive and the one for your architecture on the
phone to a place where it's allowed to run files (not `/sdcard` or `/data/media`).
Then run borg with the command:

    LD_LIBRARY_PATH=`pwd`/lib \
    PYTHONHOME=`pwd` \
    bin/python -m borg

Possibilities to reduce size (currently 9MB common + 7MB i686):
- remove more unused Python modules
- replace `openssh` by a smaller alternative

