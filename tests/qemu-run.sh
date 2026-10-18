#!/bin/sh
# OrvixOS'u QEMU'da çalıştırır (geliştirme/test aracı).
#
#   tests/qemu-run.sh install ISO   Diske otomatik kurulum yapar (sonda kapanır)
#   tests/qemu-run.sh boot          Kurulu diski başlatır (SSH: localhost:2222)
#
# Ortam: ARCH=arm64|amd64 (varsayılan arm64), DISK, HEADLESS=1

set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
arch=${ARCH:-arm64}
mode=${1:-boot}
iso=${2:-}
set --
work=$root/build/test
disk=${DISK:-$work/disk-$arch.qcow2}
share=$(dirname "$(dirname "$(command -v qemu-system-aarch64)")")/share/qemu
mkdir -p "$work"

case "$arch" in
    arm64)
        vars=$work/efivars-arm64.fd
        [ -e "$vars" ] || { dd if=/dev/zero of="$vars" bs=1m count=64 2>/dev/null; }
        accel=tcg
        [ "$(uname -s)-$(uname -m)" = Darwin-arm64 ] && accel=hvf
        set -- qemu-system-aarch64 -M virt -accel "$accel" -cpu "$([ $accel = hvf ] && echo host || echo max)" \
            -drive if=pflash,format=raw,readonly=on,file="$share/edk2-aarch64-code.fd" \
            -drive if=pflash,format=raw,file="$vars" \
            -device virtio-gpu-pci -device qemu-xhci -device usb-kbd -device usb-tablet \
            "$@"
        ;;
    amd64)
        vars=$work/efivars-amd64.fd
        [ -e "$vars" ] || cp "$share/edk2-i386-vars.fd" "$vars"
        set -- qemu-system-x86_64 -M q35 -accel tcg -cpu max \
            -drive if=pflash,format=raw,readonly=on,file="$share/edk2-x86_64-code.fd" \
            -drive if=pflash,format=raw,file="$vars" \
            -device virtio-vga -device qemu-xhci -device usb-kbd -device usb-tablet \
            "$@"
        ;;
    *) echo "ARCH arm64 ya da amd64 olmalı" >&2; exit 2 ;;
esac

[ -e "$disk" ] || qemu-img create -q -f qcow2 "$disk" 24G

set -- "$@" -smp 4 -m 4096 \
    -drive if=none,id=hd,file="$disk",format=qcow2 -device virtio-blk-pci,drive=hd \
    -netdev user,id=net,hostfwd=tcp:127.0.0.1:2222-:22 -device virtio-net-pci,netdev=net \
    -device virtio-rng-pci \
    -monitor unix:"$work/monitor-$arch.sock",server,nowait

case "$mode" in
    install)
        [ -n "$iso" ] || { echo "ISO yolu gerekli" >&2; exit 2; }
        set -- "$@" -device virtio-scsi-pci -device scsi-cd,drive=cd \
            -drive if=none,id=cd,file="$iso",media=cdrom,readonly=on \
            -serial file:"$work/install-$arch.log" -display none -no-reboot
        ;;
    boot)
        set -- "$@" -serial file:"$work/boot-$arch.log"
        [ "${HEADLESS:-0}" = 1 ] && set -- "$@" -display none
        ;;
esac

exec "$@"
