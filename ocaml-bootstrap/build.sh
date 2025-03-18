#!/bin/bash

ROOT="/root/bootstrap"
SOURCES="$ROOT/sources"
DEPENDENCIES="$ROOT/dependencies"
OVERLAY="$ROOT/overlay"
BOOTSTRAP_ROOT="$ROOT/merged"

if [[ ! -e "/build.sh" ]]; then
    overlay_store="$ROOT/overlayfs"
    [[ -d "$BOOTSTRAP_ROOT" ]] && { umount -q "$BOOTSTRAP_ROOT"; rm -rf "$BOOTSTRAP_ROOT"; }
    [[ -d "$OVERLAY" ]] && { umount -q "$OVERLAY"; rm -rf "$OVERLAY" "$overlay_store"; }
    
    dd status=none if=/dev/null bs=1 seek=1024000000000 "of=$overlay_store"
    mkfs.ext4 -q "$overlay_store"
    mkdir -p "$OVERLAY"
    mount -o discard "$overlay_store" "$OVERLAY"

    # Setup dependencies.
    # Copy dependencies into chroot. We'll try to get rid of these.
    rm -rf "$DEPENDENCIES"
    mkdir -p "$DEPENDENCIES/"{bin,lib,lib64,lib/x86_64-linux-gnu}

    cp /bin/{bash,ls,make,nproc,rm,find,xargs,touch,cp,sh,sed,mkdir,cat,uname,head,grep,tr,sort,uniq} \
        "$DEPENDENCIES/bin/"
    cp /lib/x86_64-linux-gnu/{libtinfo.so.6,libselinux.so.1,libc.so.6,libpcre2-8.so.0,libacl.so.1} \
        "$DEPENDENCIES/lib/x86_64-linux-gnu/"
    cp /lib64/ld-linux-x86-64.so.2 \
        "$DEPENDENCIES/lib64/"

    mkdir -p "$OVERLAY/upper" "$OVERLAY/work"
    mkdir -p "$BOOTSTRAP_ROOT"
    mount -t overlay overlay -o "lowerdir=$SOURCES:$DEPENDENCIES,upperdir=$OVERLAY/upper,workdir=$OVERLAY/work" "$BOOTSTRAP_ROOT"

    exec chroot "$BOOTSTRAP_ROOT" bash /build.sh
fi


echo "Building in chroot"
ls /

exit 1

