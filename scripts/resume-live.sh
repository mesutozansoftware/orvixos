#!/bin/sh
# Yarıda kalan canlı ISO derlemesini kaldığı aşamadan sürdürür ve yayınlar.
# (Paket kurulumu bitmişse yalnızca ISO aşaması yeniden çalışır.)
#
# Kullanım: scripts/resume-live.sh arm64|amd64

set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
. ./orvixos.conf

arch=${1:?Kullanım: scripts/resume-live.sh arm64|amd64}
work=/srv/orvixos-live/work-$arch
iso=OrvixOS-$ORVIXOS_VERSION-live-$arch.iso

vm_up() {
    ssh -q -i build/test/id_ed25519 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=3 -p 2222 orvix@127.0.0.1 true 2>/dev/null
}

if ! vm_up; then
    HEADLESS=1 ARCH=arm64 nohup sh tests/qemu-run.sh boot > build/test/vm.log 2>&1 &
    until vm_up; do printf '.'; sleep 5; done
    echo
fi

printf '==> %s: ISO aşaması sürdürülüyor\n' "$arch"
# Kesintiden kalan kilit ve bağlama noktaları temizlenir.
sh tests/vm.sh "rm -f $work/.lock $work/.build/lock; mount | grep $work | cut -d\" \" -f3 | sort -r | while read m; do umount -lf \$m; done"
sh tests/vm.sh "cd $work && lb binary > /srv/orvixos-live/resume-$arch.log 2>&1; tail -3 /srv/orvixos-live/resume-$arch.log; ls $work/*.iso"

printf '==> ISO alınıyor\n'
sh tests/vm.sh "cp $work/OrvixOS-$ORVIXOS_VERSION-live-$arch.hybrid.iso /tmp/$iso && chmod 644 /tmp/$iso"
scp -q -i build/test/id_ed25519 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -P 2222 "orvix@127.0.0.1:/tmp/$iso" "outputs/$iso"
sh tests/vm.sh "rm -f /tmp/$iso"
(cd outputs && shasum -a 256 "$iso" > "$iso.sha256" && cat "$iso.sha256")

SKIP_BUILD=1 sh scripts/release.sh "$arch"
