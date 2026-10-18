#!/bin/sh
# OrvixOS paketlerini (.deb) üretir.
#
# Kullanım: scripts/build-debs.sh [arm64|amd64 ...]
# Çıktı:    build/debs/<mimari>/*.deb
#
# macOS ve Linux'ta çalışır; dpkg-deb gerekmez (tools/mkdeb.py).

set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$root/orvixos.conf"

downloads=$root/downloads
vendor=$root/vendor
build=$root/build
# Ara dosyalar boşluk içermeyen geçici bir yolda hazırlanır (TRLDE Makefile).
stage_root=$(mktemp -d "${TMPDIR:-/tmp}/orvixos-stage.XXXXXX")
trap 'rm -rf "$stage_root"' EXIT HUP INT TERM

[ "$#" -gt 0 ] || set -- $ORVIXOS_ARCHES

for command_name in python3 unzip gzip make; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Gerekli komut bulunamadı: %s\n' "$command_name" >&2
        exit 127
    }
done

# @DEĞİŞKEN@ yer tutucularını sürüm bilgileriyle doldurur.
render() {
    sed \
        -e "s/@ORVIXOS_VERSION@/$ORVIXOS_VERSION/g" \
        -e "s/@ORVIXOS_CODENAME@/$ORVIXOS_CODENAME/g" \
        -e "s/@DEBIAN_MAJOR@/$DEBIAN_MAJOR/g" \
        -e "s/@DEBIAN_CODENAME@/$DEBIAN_CODENAME/g" \
        -e "s/@VPX_VERSION@/$VPX_VERSION/g" \
        -e "s/@TRLDE_VERSION@/$TRLDE_VERSION/g" \
        -e "s/@VIRA_VERSION@/$VIRA_VERSION/g" \
        -e "s/@ELECTRON_VERSION@/$ELECTRON_VERSION/g" \
        -e "s/@DEB_ARCH@/${deb_arch:-all}/g" \
        "$@"
}

# Bir paketin DEBIAN dizinini yer tutucuları doldurarak kopyalar.
control_dir() {
    package=$1
    target=$2
    mkdir -p "$target"
    for file in "$root/packages/$package/DEBIAN/"*; do
        render "$file" > "$target/$(basename "$file")"
    done
}

copyright() {
    target=$1/usr/share/doc/$2
    mkdir -p "$target"
    {
        printf 'Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/\n'
        printf 'Upstream-Name: %s\n\n' "$2"
        printf 'Files: *\nCopyright: %s\nLicense: %s\n' "$3" "$4"
        if [ -n "${5:-}" ]; then
            printf '\n'
            sed 's/^$/./; s/^/ /' "$5"
        fi
    } > "$target/copyright"
}

build_deb() {
    name=$1
    stage=$2
    control=$3
    output=$4
    shift 4
    python3 "$root/tools/mkdeb.py" --root "$stage" --control "$control" --output "$output" "$@"
}

rm -rf "$build/debs"
mkdir -p "$build/debs/all"

# --- vpx -------------------------------------------------------------------
stage=$stage_root/vpx/root
mkdir -p "$stage/usr/bin" "$stage/usr/share/bash-completion/completions" "$stage/usr/share/man/man8"
render "$root/packages/vpx/vpx" > "$stage/usr/bin/vpx"
chmod 755 "$stage/usr/bin/vpx"
cp "$root/packages/vpx/vpx.bash-completion" "$stage/usr/share/bash-completion/completions/vpx"
gzip -9n -c "$root/packages/vpx/vpx.8" > "$stage/usr/share/man/man8/vpx.8.gz"
copyright "$stage" vpx "2026 OrvixOS Project" MIT "$root/LICENSE"
control_dir vpx "$stage_root/vpx/DEBIAN"
build_deb vpx "$stage" "$stage_root/vpx/DEBIAN" "$build/debs/all/vpx_${VPX_VERSION}_all.deb"

# --- trlde -----------------------------------------------------------------
stage=$stage_root/trlde/root
make -s -C "$root/desktop/trlde" install DESTDIR="$stage" >/dev/null
copyright "$stage" trlde "2026 TRLDE geliştiricileri" MIT "$root/desktop/trlde/LICENSE"
control_dir trlde "$stage_root/trlde/DEBIAN"
build_deb trlde "$stage" "$stage_root/trlde/DEBIAN" "$build/debs/all/trlde_${TRLDE_VERSION}_all.deb"

# --- orvixos-base ----------------------------------------------------------
stage=$stage_root/orvixos-base/root
mkdir -p "$stage"
(cd "$root/packages/orvixos-base/root" && find . -type d) | while IFS= read -r dir; do
    mkdir -p "$stage/$dir"
done
(cd "$root/packages/orvixos-base/root" && find . -type f) | while IFS= read -r file; do
    render "$root/packages/orvixos-base/root/$file" > "$stage/$file"
    if [ -x "$root/packages/orvixos-base/root/$file" ]; then chmod 755 "$stage/$file"; fi
done
mkdir -p "$stage/usr/share/pixmaps" "$stage/usr/share/icons/hicolor/scalable/apps" "$stage/usr/share/icons/hicolor/256x256/apps"
cp "$root/branding/orvixos-logo.svg" "$stage/usr/share/pixmaps/orvixos-logo.svg"
cp "$root/branding/orvixos-logo-256.png" "$stage/usr/share/pixmaps/orvixos-logo.png"
cp "$root/branding/orvixos-logo.svg" "$stage/usr/share/icons/hicolor/scalable/apps/orvixos.svg"
cp "$root/branding/orvixos-logo-256.png" "$stage/usr/share/icons/hicolor/256x256/apps/orvixos.png"
cp "$root/branding/orvixos-logo-256.png" "$stage/usr/share/plymouth/themes/orvixos/logo.png"
copyright "$stage" orvixos-base "2026 OrvixOS Project" MIT "$root/LICENSE"
control_dir orvixos-base "$stage_root/orvixos-base/DEBIAN"
build_deb orvixos-base "$stage" "$stage_root/orvixos-base/DEBIAN" "$build/debs/all/orvixos-base_${ORVIXOS_VERSION}_all.deb"

# --- orvixos-desktop -------------------------------------------------------
stage=$stage_root/orvixos-desktop/root
mkdir -p "$stage"
cp -R "$root/packages/orvixos-desktop/root/." "$stage/"
copyright "$stage" orvixos-desktop "2026 OrvixOS Project" MIT "$root/LICENSE"
control_dir orvixos-desktop "$stage_root/orvixos-desktop/DEBIAN"
build_deb orvixos-desktop "$stage" "$stage_root/orvixos-desktop/DEBIAN" "$build/debs/all/orvixos-desktop_${ORVIXOS_VERSION}_all.deb"

# --- vira-browser (mimariye özgü) ------------------------------------------
for deb_arch in "$@"; do
    case "$deb_arch" in
        arm64) electron_arch=arm64 ;;
        amd64) electron_arch=x64 ;;
        *) printf 'Desteklenmeyen mimari: %s\n' "$deb_arch" >&2; exit 2 ;;
    esac
    electron_zip=$downloads/electron-v$ELECTRON_VERSION-linux-$electron_arch.zip
    ffmpeg_zip=$downloads/ffmpeg-v$ELECTRON_VERSION-linux-$electron_arch.zip
    for file in "$electron_zip" "$ffmpeg_zip" "$vendor/vira-browser/app.asar"; do
        [ -r "$file" ] || { printf 'Eksik dosya: %s (önce scripts/fetch.sh)\n' "$file" >&2; exit 1; }
    done

    stage=$stage_root/vira-browser-$deb_arch/root
    app=$stage/usr/lib/vira-browser
    mkdir -p "$app" "$stage/usr/bin" "$stage/usr/share/applications" \
        "$stage/usr/share/icons/hicolor/256x256/apps" "$stage/usr/share/icons/hicolor/1024x1024/apps"
    unzip -q -o "$electron_zip" -d "$app"
    # Patentli kodek içermeyen ffmpeg (yalnızca özgür kodekler).
    unzip -q -o "$ffmpeg_zip" -d "$app"
    mv "$app/electron" "$app/vira-browser"
    rm -f "$app/resources/default_app.asar"
    cp "$vendor/vira-browser/app.asar" "$app/resources/app.asar"
    cp "$root/packages/vira-browser/vira-browser.sh" "$stage/usr/bin/vira-browser"
    chmod 755 "$stage/usr/bin/vira-browser"
    cp "$root/packages/vira-browser/vira-browser.desktop" "$stage/usr/share/applications/"
    cp "$vendor/vira-browser/icon-256.png" "$stage/usr/share/icons/hicolor/256x256/apps/vira-browser.png"
    cp "$vendor/vira-browser/icon.png" "$stage/usr/share/icons/hicolor/1024x1024/apps/vira-browser.png"
    copyright "$stage" vira-browser "2026 Vira Browser" \
        "MIT (Vira Browser ve Electron); Chromium bileşenleri: /usr/lib/vira-browser/LICENSES.chromium.html" \
        "$app/LICENSE"
    control_dir vira-browser "$stage_root/vira-browser-$deb_arch/DEBIAN"

    mkdir -p "$build/debs/$deb_arch"
    build_deb vira-browser "$stage" "$stage_root/vira-browser-$deb_arch/DEBIAN" \
        "$build/debs/$deb_arch/vira-browser_${VIRA_VERSION}_$deb_arch.deb" \
        --mode usr/lib/vira-browser/chrome-sandbox=4755
    cp "$build/debs/all/"*.deb "$build/debs/$deb_arch/"
    rm -rf "$stage_root/vira-browser-$deb_arch"
done

printf 'Paketler hazır: %s\n' "$build/debs"
