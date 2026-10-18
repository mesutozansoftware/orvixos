#!/bin/sh
# Derleme için gereken dış dosyaları indirir ve SHA-256 ile doğrular:
# Debian netinst ISO'ları, Debian paket dizinleri, Electron ve ffmpeg.

set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$root/orvixos.conf"
downloads=$root/downloads
mkdir -p "$downloads"
cd "$downloads"

fetch() {
    [ -s "$1" ] || { printf 'İndiriliyor: %s\n' "$1"; curl -fL --retry 3 -C - -o "$1" "$2"; }
}

electron_base=https://github.com/electron/electron/releases/download/v$ELECTRON_VERSION
fetch electron-SHASUMS256.txt "$electron_base/SHASUMS256.txt"

for arch in $ORVIXOS_ARCHES; do
    case "$arch" in
        arm64) electron_arch=arm64 ;;
        amd64) electron_arch=x64 ;;
    esac
    iso=debian-$DEBIAN_VERSION-$arch-netinst.iso
    curl -fsSL -o "debian-$arch-SHA256SUMS" "https://cdimage.debian.org/debian-cd/$DEBIAN_VERSION/$arch/iso-cd/SHA256SUMS"
    fetch "$iso" "https://cdimage.debian.org/debian-cd/$DEBIAN_VERSION/$arch/iso-cd/$iso"
    grep " $iso\$" "debian-$arch-SHA256SUMS" | shasum -a 256 -c -

    curl -fsSL -o "Packages-$arch.xz" "https://$DEBIAN_MIRROR/debian/dists/$DEBIAN_CODENAME/main/binary-$arch/Packages.xz"

    for name in electron ffmpeg; do
        file=$name-v$ELECTRON_VERSION-linux-$electron_arch.zip
        fetch "$file" "$electron_base/$file"
        grep " \*$file\$" electron-SHASUMS256.txt | sed 's/ \*/  /' | shasum -a 256 -c -
    done
done

# Vira Browser uygulaması (app.asar) depoda vendor/ altında tutulur; yoksa
# macOS'ta kurulu uygulamadan alınır.
vira=$root/vendor/vira-browser/app.asar
if [ ! -r "$vira" ] && [ -r "/Applications/Vira Browser.app/Contents/Resources/app.asar" ]; then
    mkdir -p "$(dirname "$vira")"
    cp "/Applications/Vira Browser.app/Contents/Resources/app.asar" "$vira"
fi
[ -r "$vira" ] || { printf 'Vira Browser app.asar bulunamadı: %s\n' "$vira" >&2; exit 1; }

printf 'Tüm kaynaklar hazır: %s\n' "$downloads"
