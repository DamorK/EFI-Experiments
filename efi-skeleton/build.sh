#!/bin/bash

cd "$(dirname "$0")" || exit 1

BUILD_DIR="./build"
DISK_LOOP_DEV=
DISK_MOUNT_DIR=

cleanup() {
    [[ -n "$DISK_MOUNT_DIR" ]] && {
        echo "Removing disk mount point" >&2
        sudo umount "$DISK_MOUNT_DIR"
        rm -r "$DISK_MOUNT_DIR"
    }
    [[ -n "$DISK_LOOP_DEV" ]] && {
        echo "Removing disk loop device" >&2
        sudo losetup -d "$DISK_LOOP_DEV"
    }
}

trap cleanup EXIT

build_app() {
    echo "Building EFI application" >&2
    cmake -B "$BUILD_DIR" && cmake --build "$BUILD_DIR"
}

build_disk() {
    [[ -f "$BUILD_DIR/disk.img" ]] && return 0
    
    # Create GPT disk with a single FAT32 partition
    echo "Building disk image" >&2
    dd if=/dev/zero of="$BUILD_DIR/disk.img" bs=1K count=48K &&
        parted -ms "$BUILD_DIR/disk.img" "mktable GPT" &&
        parted -ms "$BUILD_DIR/disk.img" "mkpart primary FAT32 1M -1M" &&
        DISK_LOOP_DEV="$(sudo losetup --show -P -f "$BUILD_DIR/disk.img")" &&
        sudo mkdosfs -F 32 "${DISK_LOOP_DEV}p1"
}

deploy_app() {
    [[ -n "$DISK_LOOP_DEV" ]] ||
        DISK_LOOP_DEV="$(sudo losetup --show -P -f "$BUILD_DIR/disk.img")" ||
        return 1
    
    echo "Installing EFI application on the disk image"
    DISK_MOUNT_DIR="$(mktemp -d)" &&
        sudo mount "${DISK_LOOP_DEV}p1" "$DISK_MOUNT_DIR" &&
        sudo cp "$BUILD_DIR/app.efi" "$DISK_MOUNT_DIR/"
}

build_app && build_disk && deploy_app
