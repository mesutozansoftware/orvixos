#!/bin/sh
# OrvixOS canlı ISO'sunu live-build ile üretir. Bir Debian 13 sisteminde
# root olarak çalışır (scripts/build-live.sh bunu derleme sanal makinesinde
# çağırır).
#
# Kullanım: build-in-vm.sh KAYNAK_DİZİNİ arm64|amd64 SÜRÜM

set -eu

src=$1
arch=$2
version=$3
work=/srv/orvixos-live/work-$arch

case "$arch" in
    arm64)
        flavour=arm64
        bootloaders=grub-efi
        # ARM'da ACPI SPCR seri portu konsol yapar; ekranda kalsın.
        extra_append="acpi=nospcr console=tty0"
        ;;
    amd64)
        flavour=amd64
        bootloaders=grub-efi,syslinux
        extra_append=""
        ;;
    *) echo "Desteklenmeyen mimari: $arch" >&2; exit 2 ;;
esac

rm -rf "$work"
mkdir -p "$work"
cd "$work"

lb config noauto \
    --mode debian \
    --system live \
    --distribution trixie \
    --architecture "$arch" \
    --linux-flavours "$flavour" \
    --archive-areas "main contrib non-free-firmware" \
    --mirror-bootstrap http://deb.debian.org/debian/ \
    --mirror-chroot http://deb.debian.org/debian/ \
    --mirror-binary http://deb.debian.org/debian/ \
    --mirror-chroot-security http://security.debian.org/debian-security/ \
    --mirror-binary-security http://security.debian.org/debian-security/ \
    --security true \
    --updates true \
    --apt-recommends false \
    --bootloaders "$bootloaders" \
    --binary-images iso-hybrid \
    --debian-installer none \
    --memtest none \
    --firmware-chroot false \
    --firmware-binary false \
    --chroot-squashfs-compression-type xz \
    --iso-application "OrvixOS" \
    --iso-publisher "OrvixOS Project" \
    --iso-volume "OrvixOS $version $arch" \
    --image-name "OrvixOS-$version-live" \
    --checksums sha256 \
    --zsync false \
    --bootappend-live "boot=live components quiet splash locales=tr_TR.UTF-8 keyboard-layouts=tr username=orvix user-fullname=OrvixOS hostname=orvixos $extra_append"

# OrvixOS yapılandırması: paket listeleri, yerel paketler, chroot dosyaları,
# kancalar.
cp -a "$src/config/." config/

# GRUB menüsü: live-build şablonu + OrvixOS menüsü ve arka planı.
mkdir -p config/bootloaders
cp -a /usr/share/live/build/bootloaders/grub-pc config/bootloaders/
cp "$src/bootloader/grub.cfg" config/bootloaders/grub-pc/grub.cfg
cp "$src/bootloader/splash.png" config/bootloaders/grub-pc/splash.png
cp "$src/bootloader/splash.png" config/bootloaders/splash.png
sed -i 's/^title-text: .*/title-text: ""/' config/bootloaders/grub-pc/live-theme/theme.txt
if [ "$arch" = amd64 ]; then
    cp -a /usr/share/live/build/bootloaders/isolinux config/bootloaders/
    cp "$src/bootloader/splash.png" config/bootloaders/isolinux/splash.png
    sed -i 's/^\(\s*menu title\).*/\1 OrvixOS/' config/bootloaders/isolinux/*.cfg 2>/dev/null || true
fi

lb build 2>&1 | tee build.log
ls -la "$work"/*.iso
