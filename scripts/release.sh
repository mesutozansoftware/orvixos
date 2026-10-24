#!/bin/sh
# OrvixOS'u baştan sona yayınlar: paketler → canlı ISO'lar → GitHub → site.
#
# Kullanım:
#   scripts/release.sh                 # arm64 + amd64, her şey
#   scripts/release.sh arm64           # yalnızca ARM64
#   SKIP_BUILD=1 scripts/release.sh    # derleme yok; outputs/ içindekileri yayınla
#   SKIP_SITE=1  scripts/release.sh    # siteyi güncelleme
#
# Gerekenler (bir kez): Homebrew ile qemu, xorriso, gh; Node.js (npx);
#   gh auth login            (GitHub hesabı)
#   npx vercel@48.10.0 login (Vercel hesabı)
# Canlı ISO'lar build/test/disk-arm64.qcow2 içindeki Debian derleme sanal
# makinesinde üretilir (ayrıntılar: NASIL.md).

set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
. ./orvixos.conf

[ "$#" -gt 0 ] || set -- arm64 amd64
repo=mesutozansoftware/orvixos
tag=v$ORVIXOS_VERSION

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
die() { printf '\033[1;31mHATA: %s\033[0m\n' "$*" >&2; exit 1; }

for tool in gh npx python3 qemu-system-aarch64 xorriso ssh scp; do
    command -v "$tool" >/dev/null 2>&1 || die "$tool bulunamadı (NASIL.md: Gerekenler)"
done
gh auth status >/dev/null 2>&1 || die "GitHub'a giriş yapılmamış: gh auth login"

vm_up() {
    ssh -q -i build/test/id_ed25519 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=3 -p 2222 orvix@127.0.0.1 true 2>/dev/null
}

if [ "${SKIP_BUILD:-0}" != 1 ]; then
    say "Derleme sanal makinesi"
    [ -f build/test/disk-arm64.qcow2 ] || die "build/test/disk-arm64.qcow2 yok (NASIL.md: Derleme makinesini sıfırdan kurmak)"
    if ! vm_up; then
        HEADLESS=1 ARCH=arm64 nohup sh tests/qemu-run.sh boot > build/test/vm.log 2>&1 &
        printf 'Sanal makine açılıyor'
        i=0
        until vm_up; do
            i=$((i + 1)); [ "$i" -lt 60 ] || die "Sanal makineye SSH ile bağlanılamadı (build/test/vm.log)"
            printf '.'; sleep 5
        done
        printf ' hazır\n'
    fi
    # QEMU ağında yavaş DNS'i önler (her paket için 5 sn beklemesin).
    # Yarım kalmış derlemenin bağlama noktaları (proc/sys/dev) silmeden önce ayrılır.
    sh tests/vm.sh 'grep -q single-request /etc/resolv.conf || echo "options single-request-reopen timeout:1 attempts:2" >> /etc/resolv.conf; mount | grep /srv/orvixos-live | cut -d" " -f3 | sort -r | while read m; do umount -lf "$m"; done; rm -rf /srv/orvixos-live/work-* /srv/orvixos-live/src-*'

    say "OrvixOS paketleri"
    [ -f downloads/Packages-arm64.xz ] || sh scripts/fetch.sh
    ORVIXOS_REUSE_VIRA=1 sh scripts/build-debs.sh "$@"

    for arch in "$@"; do
        say "Canlı ISO: $arch (ARM64 ~15 dk, x64 ~40 dk)"
        sh scripts/build-live.sh "$arch"
        sh tests/vm.sh "rm -rf /srv/orvixos-live/work-$arch"
    done
fi

say "GitHub'a yükleme ($repo $tag)"
if ! gh release view "$tag" --repo "$repo" >/dev/null 2>&1; then
    gh release create "$tag" --repo "$repo" --title "OrvixOS $ORVIXOS_VERSION “$ORVIXOS_CODENAME”" \
        --notes "OrvixOS $ORVIXOS_VERSION “$ORVIXOS_CODENAME” canlı ISO'ları (ARM64 ve x64). Ayrıntılar: https://orvixos.is-a.dev — yedek: https://orvixos.vercel.app"
fi
for arch in "$@"; do
    iso=outputs/OrvixOS-$ORVIXOS_VERSION-live-$arch.iso
    [ -f "$iso" ] || die "$iso yok"
    gh release upload "$tag" --repo "$repo" --clobber "$iso" "$iso.sha256"
    printf '%s yüklendi\n' "$iso"
done

if [ "${SKIP_SITE:-0}" != 1 ]; then
    say "Site: SHA-256 ve boyutlar"
    python3 tools/update-site.py "$@"
    say "Site: Vercel'de yayınla"
    (cd site && npx -y vercel@48.10.0 deploy --prod --yes)
fi

say "Kaynak kodu: GitHub"
git add -A site desktop packages live scripts tools iso branding tests README.md NASIL.md 2>/dev/null || true
if ! git diff --cached --quiet; then
    git commit -q -m "OrvixOS $ORVIXOS_VERSION: canlı ISO'lar ve site güncellendi"
    git push -q
fi

say "Bitti"
printf 'İndirmeler: https://github.com/%s/releases/tag/%s\nSite: https://orvixos.is-a.dev (yedek: https://orvixos.vercel.app)\n' "$repo" "$tag"
