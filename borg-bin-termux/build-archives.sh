#!/bin/bash

ARCHS="i686"

BORG_PKGS="
  attr libacl
  liblzma liblz4 zstd
  libffi openssl python
  borgbackup
"
SSH_PKGS="
  libandroid-glob libandroid-support
  ldns krb5 libdb
  openssh
"

get_package_url() {
  arch="$1"
  pkg="$2"
  prefix=`echo "$pkg" | sed 's/^\(lib\)\?\(.\).*$/\1\2/'`
  echo -n "https://packages.termux.org/apt/termux-main/pool/main/$prefix/$pkg/"
  curl -s "https://packages.termux.org/apt/termux-main/pool/main/$prefix/$pkg/" | grep "_$arch.deb" | cut -d\" -f2
}

get_bootstrap_url() {
  arch="$1"
  curl -s https://api.github.com/repos/termux/termux-packages/releases/latest | grep "/bootstrap-$arch.zip" | cut -d\" -f4
}

mkdir -p cache
for arch in $ARCHS; do
  rm -Rf "prefix-$arch"
  mkdir -p "prefix-$arch"

  # download and extract all packages
  for pkg in $BORG_PKGS $SSH_PKGS; do
    [ -e "cache/$pkg-$arch.deb" ] || curl -s -o "cache/$pkg-$arch.deb" `get_package_url "$arch" "$pkg"`
    dpkg-deb -x "cache/$pkg-$arch.deb" "prefix-$arch/"
  done

  # remove termux prefix
  mv "prefix-$arch"/data/data/com.termux/files/usr/* "prefix-$arch/"
  rm -Rf "prefix-$arch/data"

  # add missing libraries from bootstrap
  [ -e "cache/bootstrap-$arch.zip" ] || curl -s -L -o "cache/bootstrap-$arch.zip" `get_bootstrap_url "$arch"`
  unzip -q -d "prefix-$arch/" "cache/bootstrap-$arch.zip" "lib/libz*"
  [ ! -e "prefix-$arch"/lib/libz.so.1 ] && ln -s `cd "prefix-$arch"/lib/ && ls libz.so.* | head -n1` "prefix-$arch"/lib/libz.so.1

  # we need pkg_resources from setuptools
  unzip -q -d "prefix-$arch"/lib/python*/ "prefix-$arch"/lib/python*/ensurepip/_bundled/setuptools-*.whl "pkg_resources/*"

  # remove files we don't use to save space
  rm -Rf "prefix-$arch"/{share,libexec,include,var,etc}
  rm -Rf "prefix-$arch"/lib/{krb5,pkgconfig,engines*}
  rm -Rf "prefix-$arch"/lib/python*/{lib2to3,html,xmlrpc,venv,sqlite3,curses,dbm,config-*,ensurepip,wsgiref,http,pydoc_data}
  rm -Rf "prefix-$arch"/lib/python*/site-packages/xcbgen
  find "prefix-$arch"/lib/python*/distutils/ ! -type d | grep -v '/version\.\(py\|.*\.pyc\)$' | xargs rm -Rf
  find "prefix-$arch"/bin ! -type d | grep -v '/\(python[0-9.]*\|ssh\|ssh-keygen\)$' | xargs rm -f

  # move borgbackup from site-packages to main pythonpath to simplify invocation
  mv "prefix-$arch"/lib/python*/site-packages/borgbackup-*/borg "prefix-$arch"/lib/python*/
  rm -Rf "prefix-$arch"/lib/python*/site-packages/borgbackup-*

  # create final archives
  tar -c -z -C "prefix-$arch" --exclude \*.so --exclude \*.so.\* --exclude bin --exclude bin/* -f "borg-common.tgz" .
  ( cd "prefix-$arch" && find . -type f -name \*.so -o -name \*.so.\* | xargs tar -c -z -f "../borg-$arch.tgz" ./bin )
done
