#!/bin/sh
# Yayındaki canlı ISO'ları baştan derlemeden günceller ve yayınlar.
# Değişen OrvixOS paketleri (masaüstü, ayarlar, markalama) ve canlı sistem
# dosyaları ISO'daki sisteme kurulur; Debian tabanı yeniden kurulmaz.
#
# Kullanım: scripts/patch-live.sh [arm64] [amd64]
# Temel: outputs/OrvixOS-<sürüm>-live-<mimari>.iso (önceki derleme)

set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
. ./orvixos.conf
[ "$#" -gt 0 ] || set -- arm64 amd64

key=build/test/id_ed25519
ssh_opts="-q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ServerAliveInterval=30"
vm_up() { ssh $ssh_opts -i "$key" -o ConnectTimeout=3 -p 2222 orvix@127.0.0.1 true 2>/dev/null; }
to_vm() { scp $ssh_opts -i "$key" -P 2222 "$1" "orvix@127.0.0.1:$2"; }
from_vm() { scp $ssh_opts -i "$key" -P 2222 "orvix@127.0.0.1:$1" "$2"; }

if ! vm_up; then
    HEADLESS=1 ARCH=arm64 nohup sh tests/qemu-run.sh boot > build/test/vm.log 2>&1 &
    printf 'Sanal makine açılıyor'
    until vm_up; do printf '.'; sleep 5; done
    echo
fi

echo "==> OrvixOS paketleri"
ORVIXOS_REUSE_VIRA=1 sh scripts/build-debs.sh "$@" >/dev/null

sh tests/vm.sh 'mount | grep /srv/orvixos-live | cut -d" " -f3 | sort -r | while read m; do umount -lf "$m"; done; rm -rf /srv/orvixos-live/work-* /srv/orvixos-live/patch* /srv/orvixos-live/src-*; mkdir -p /srv/orvixos-live/in; chmod 777 /srv/orvixos-live/in'

for arch in "$@"; do
    iso=OrvixOS-$ORVIXOS_VERSION-live-$arch.iso
    [ -f "outputs/$iso" ] || { echo "outputs/$iso yok; önce scripts/release.sh $arch" >&2; exit 1; }
    start=$(date +%s)
    echo "==> $arch: ISO sanal makineye gönderiliyor"
    stage=build/patch-src/$arch
    rm -rf "$stage"
    mkdir -p "$stage/debs" "$stage/hooks"
    # Vira değişmediği için gönderilmez (imajda zaten var).
    for deb in build/debs/$arch/*.deb; do
        case "$(basename "$deb")" in vira-browser_*) ;; *) cp "$deb" "$stage/debs/" ;; esac
    done
    cp -R live/config/includes.chroot "$stage/includes"
    cp live/config/hooks/live/*.hook.chroot "$stage/hooks/"
    cp live/patch-in-vm.sh "$stage/"
    (cd "$stage" && COPYFILE_DISABLE=1 tar --no-xattrs -cf ../$arch.tar .)
    to_vm "outputs/$iso" "/srv/orvixos-live/in/$iso"
    to_vm "build/patch-src/$arch.tar" "/srv/orvixos-live/in/src-$arch.tar"

    echo "==> $arch: güncelleniyor"
    sh tests/vm.sh "mkdir -p /srv/orvixos-live/src-$arch && tar -C /srv/orvixos-live/src-$arch -xf /srv/orvixos-live/in/src-$arch.tar && sh /srv/orvixos-live/src-$arch/patch-in-vm.sh /srv/orvixos-live/in/$iso /srv/orvixos-live/src-$arch /srv/orvixos-live/out-$iso"

    echo "==> $arch: ISO alınıyor"
    sh tests/vm.sh "chmod 644 /srv/orvixos-live/out-$iso"
    from_vm "/srv/orvixos-live/out-$iso" "outputs/$iso"
    sh tests/vm.sh "rm -rf /srv/orvixos-live/out-$iso /srv/orvixos-live/in/$iso /srv/orvixos-live/in/src-$arch.tar /srv/orvixos-live/src-$arch"
    (cd outputs && shasum -a 256 "$iso" > "$iso.sha256" && cat "$iso.sha256")
    echo "==> $arch: $(( ($(date +%s) - start) / 60 )) dakikada güncellendi"
done

SKIP_BUILD=1 sh scripts/release.sh "$@"
