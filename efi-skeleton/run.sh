#!/bin/bash

cd "$(dirname "$0")" || exit 1

BUILD_DIR="./build"
OVMF_URL="https://retrage.github.io/edk2-nightly/bin/RELEASEX64_OVMF.fd"

# Download UEFI firmware for QEMU
[[ -f OVMF.fd ]] || curl -o OVMF.fd "$OVMF_URL"

# Start QEMU
qemu-system-x86_64 -cpu qemu64 -bios OVMF.fd -drive file="$BUILD_DIR/disk.img",if=ide -net none
