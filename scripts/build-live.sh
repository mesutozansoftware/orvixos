#!/bin/sh
# OrvixOS canlı (live) ISO'sunu üretir.
#
# live-build yalnızca Debian'da çalıştığı için derleme, SSH ile erişilen bir
# Debian 13 sanal makinesinde yapılır (varsayılan: tests/qemu-run.sh ile
# başlatılan test makinesi, localhost:2222).
#
# Kullanım: scripts/build-live.sh arm64|amd64
# Çıktı:    outputs/OrvixOS-<sürüm>-live-<mimari>.iso

set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$root/orvixos.conf"

arch=${1:-}
case "$arch" in
    arm64) bootloader_pool="grub-efi grub-efi-arm64 grub-efi-arm64-bin"
           bootloader_chroot="grub-efi-arm64-bin efibootmgr" ;;
    amd64) bootloader_pool="grub-efi grub-efi-amd64 grub-efi-amd64-bin"
           bootloader_chroot="grub-efi-amd64-bin grub-pc-bin efibootmgr" ;;
    *) printf 'Kullanım: %s arm64|amd64\n' "$0" >&2; exit 2 ;;
esac
# Sürücüler ve donanım yazılımları: live/drivers.list
firmware=$(sh "$root/tools/drivers.sh" "$arch" | tr '\n' ' ')

vm="$root/tests/vm.sh"
key=$root/build/test/id_ed25519
vm_ssh() {
    ssh -q -i "$key" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o ServerAliveInterval=30 -p 2222 orvix@127.0.0.1 "$@"
}
vm_fetch() {
    scp -q -i "$key" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -P 2222 "orvix@127.0.0.1:$1" "$2"
}
stage=$root/build/live-src/$arch
rm -rf "$stage"
mkdir -p "$stage/config/packages.chroot" "$stage/config/package-lists" "$stage/bootloader"

# Yapılandırma ağacı
cp -R "$root/live/config/." "$stage/config/"
cp "$root/live/bootloader/grub.cfg" "$stage/bootloader/grub.cfg"
cp "$root/branding/live-boot-splash.png" "$stage/bootloader/splash.png"
cp "$root/live/build-in-vm.sh" "$stage/build-in-vm.sh"

# OrvixOS paketleri (yerel .deb'ler chroot'a bağımlılıklarıyla kurulur)
ls "$root/build/debs/$arch"/vira-browser_*_"$arch".deb >/dev/null 2>&1 || {
    printf 'Önce paketleri üret: scripts/build-debs.sh %s\n' "$arch" >&2
    exit 1
}
cp "$root/build/debs/$arch"/*.deb "$stage/config/packages.chroot/"

# Paket listeleri
{
    python3 "$root/tools/pkglist.py" include | tr ' ' '\n'
    printf '%s\n' vpx trlde vira-browser orvixos-base orvixos-desktop \
        sddm qml6-module-qtquick-controls qml6-module-qtquick-layouts zenity \
        calamares calamares-settings-debian \
        live-boot live-config live-config-systemd user-setup \
        locales console-setup keyboard-configuration sudo \
        cryptsetup cryptsetup-initramfs keyutils os-prober \
        firmware-linux-free $firmware $bootloader_chroot
} | sort -u > "$stage/config/package-lists/orvixos.list.chroot"
# BIOS kurulumları için grub-pc ayrı .deb olarak eklenir: grub-efi-amd64 ile
# çakıştığı için aynı paket listesinde çözümlenemez.
if [ "$arch" = amd64 ]; then
    mkdir -p "$stage/config/packages.binary"
    grub_pc=$(python3 -c "
import lzma, re, sys
data = lzma.open(sys.argv[1]).read().decode()
for block in data.split('\\n\\n'):
    if re.search(r'^Package: grub-pc$', block, re.M):
        print(re.search(r'^Filename: (.+)$', block, re.M).group(1)); break
" "$root/downloads/Packages-amd64.xz")
    curl -fsSL -o "$stage/config/packages.binary/$(basename "$grub_pc")" "https://$DEBIAN_MIRROR/debian/$grub_pc"
fi
# Kurulumda internetsiz kurulabilmesi için önyükleyici paketleri ISO'ya eklenir.
printf '%s\n' $bootloader_pool cryptsetup cryptsetup-initramfs keyutils \
    > "$stage/config/package-lists/bootloader.list.binary"

printf 'Paket listesi: %s paket\n' "$(wc -l < "$stage/config/package-lists/orvixos.list.chroot" | tr -d ' ')"

# Derleme makinesine gönder ve derle
remote=/srv/orvixos-live/src-$arch
(cd "$stage" && COPYFILE_DISABLE=1 tar --no-xattrs -cf - .) |
    vm_ssh "cat > /tmp/orvixos-live-src.tar"
sh "$vm" "rm -rf $remote && mkdir -p $remote && tar -C $remote -xf /tmp/orvixos-live-src.tar && rm /tmp/orvixos-live-src.tar && chmod 755 $remote/build-in-vm.sh"
sh "$vm" "sh $remote/build-in-vm.sh $remote $arch $ORVIXOS_VERSION > /srv/orvixos-live/build-$arch.log 2>&1; tail -5 /srv/orvixos-live/build-$arch.log"

# ISO'yu geri al
mkdir -p "$root/outputs"
iso=OrvixOS-$ORVIXOS_VERSION-live-$arch.iso
sh "$vm" "cp /srv/orvixos-live/work-$arch/OrvixOS-$ORVIXOS_VERSION-live-$arch.hybrid.iso /tmp/$iso && chmod 644 /tmp/$iso"
vm_fetch "/tmp/$iso" "$root/outputs/$iso"
sh "$vm" "rm -f /tmp/$iso"
(cd "$root/outputs" && shasum -a 256 "$iso" > "$iso.sha256")
printf 'Canlı ISO hazır: %s\n' "$root/outputs/$iso"
