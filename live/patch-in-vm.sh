#!/bin/sh
# Mevcut bir OrvixOS canlı ISO'sunu baştan derlemeden günceller (sanal makinede,
# root olarak). ISO'daki sistem imajı açılır, OrvixOS paketleri ve canlı sistem
# dosyaları yenilenir, imaj yeniden sıkıştırılıp ISO'ya konur.
#
# Kullanım: patch-in-vm.sh KAYNAK.iso KAYNAK_DİZİNİ ÇIKTI.iso
#   KAYNAK_DİZİNİ/debs/*.deb       kurulacak OrvixOS paketleri
#   KAYNAK_DİZİNİ/includes/        canlı sistem dosyaları (includes.chroot)
#   KAYNAK_DİZİNİ/hooks/*.chroot   chroot kancaları

set -eu

iso=$1
src=$2
out=$3
work=$(dirname "$out")/patch-$(basename "$out" .iso)
root=$work/root

cleanup() {
    for mount_point in dev/pts dev sys proc; do
        umount -lf "$root/$mount_point" 2>/dev/null || true
    done
}
trap cleanup EXIT INT TERM

rm -rf "$work"
mkdir -p "$work"

echo "==> Sistem imajı açılıyor"
xorriso -osirrox on -indev "$iso" -extract /live/filesystem.squashfs "$work/old.squashfs" >/dev/null 2>&1
unsquashfs -q -d "$root" "$work/old.squashfs"
rm -f "$work/old.squashfs"

echo "==> OrvixOS paketleri ve dosyaları güncelleniyor"
mkdir -p "$root/tmp/orvixos"
cp "$src"/debs/*.deb "$root/tmp/orvixos/"
cp -a "$src/includes/." "$root/"
cp "$root/etc/resolv.conf" "$work/resolv.conf.orig" 2>/dev/null || true
rm -f "$root/etc/resolv.conf"
cat /etc/resolv.conf > "$root/etc/resolv.conf"
mount -t proc proc "$root/proc"
mount --bind /sys "$root/sys"
mount --bind /dev "$root/dev"
mount --bind /dev/pts "$root/dev/pts"

chroot "$root" sh -c '
    set -e
    export DEBIAN_FRONTEND=noninteractive LC_ALL=C
    printf "#!/bin/sh\nexit 101\n" > /usr/sbin/policy-rc.d; chmod 755 /usr/sbin/policy-rc.d
    apt-get -q update
    # Sürüm numarası değişmese de yeni paketlerin kurulması için dpkg -i;
    # eksik bağımlılıklar ardından apt ile tamamlanır.
    dpkg -i /tmp/orvixos/*.deb || true
    apt-get -q -y -o APT::Install-Recommends=false -f install
    apt-get -q -y -o APT::Install-Recommends=false install pcmanfm-qt-l10n || true
    apt-get clean
    rm -f /usr/sbin/policy-rc.d
'
for hook in "$src"/hooks/*.chroot; do
    [ -f "$hook" ] || continue
    cp "$hook" "$root/tmp/orvixos/hook"
    chroot "$root" sh /tmp/orvixos/hook
done

rm -rf "$root/tmp/orvixos" "$root"/var/lib/apt/lists/*_Packages* "$root"/var/lib/apt/lists/*_Translation*
rm -f "$root/etc/resolv.conf"
[ -f "$work/resolv.conf.orig" ] && cp -a "$work/resolv.conf.orig" "$root/etc/resolv.conf" || true
cleanup

echo "==> Sistem imajı sıkıştırılıyor (birkaç dakika)"
mksquashfs "$root" "$work/filesystem.squashfs" -comp xz -noappend -quiet
du -sx --block-size=1 "$root" | cut -f1 > "$work/filesystem.size"
chroot "$root" dpkg-query -W --showformat='${Package} ${Version}\n' > "$work/filesystem.packages" 2>/dev/null || true
rm -rf "$root"

echo "==> ISO oluşturuluyor"
rm -f "$out"
xorriso -indev "$iso" -outdev "$out" \
    -map "$work/filesystem.squashfs" /live/filesystem.squashfs \
    -map "$work/filesystem.size" /live/filesystem.size \
    -boot_image any replay >/dev/null 2>&1
rm -rf "$work"
ls -la "$out"
