#!/bin/sh
# OrvixOS kurulum ISO'sunu üretir.
#
# Debian netinst ISO'su temel alınır: kurulum programına OrvixOS ön
# yanıtları (preseed), markalama ve OrvixOS paketleri eklenir. Kurulum
# sırasında Debian paketleri doğrudan Debian sunucularından indirilir.
#
# Kullanım: scripts/build-iso.sh arm64|amd64
#   ORVIXOS_TEST=1  Soru sormayan otomatik test ISO'su üretir.

set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$root/orvixos.conf"

arch=${1:-}
case "$arch" in
    # Kurulum ekranı monitörde çıksın: preseed varken debian-installer yalnızca
    # "tercih edilen" konsolu kullanır; ARM64'te ACPI SPCR bunu seri port yapar.
    arm64) install_dir=install.a64; serial=ttyAMA0; console_args="acpi=nospcr console=tty0" ;;
    amd64) install_dir=install.amd; serial=ttyS0; console_args="console=tty0" ;;
    *) printf 'Kullanım: %s arm64|amd64\n' "$0" >&2; exit 2 ;;
esac

test_mode=${ORVIXOS_TEST:-0}
base_iso=$root/downloads/debian-$DEBIAN_VERSION-$arch-netinst.iso
debs=$root/build/debs/$arch
outputs=$root/outputs
if [ "$test_mode" = 1 ]; then
    output_iso=$root/build/test/OrvixOS-$ORVIXOS_VERSION-$arch-test.iso
else
    output_iso=$outputs/OrvixOS-$ORVIXOS_VERSION-$arch.iso
fi

for command_name in xorriso python3; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Gerekli komut bulunamadı: %s\n' "$command_name" >&2
        exit 127
    }
done
[ -r "$base_iso" ] || { printf 'Debian ISO bulunamadı: %s (önce scripts/fetch.sh)\n' "$base_iso" >&2; exit 1; }
ls "$debs"/vira-browser_*_"$arch".deb >/dev/null 2>&1 || {
    printf 'OrvixOS paketleri yok: %s (önce scripts/build-debs.sh %s)\n' "$debs" "$arch" >&2
    exit 1
}

work=$(mktemp -d "${TMPDIR:-/tmp}/orvixos-iso.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM

render() {
    sed \
        -e "s/@ORVIXOS_VERSION@/$ORVIXOS_VERSION/g" \
        -e "s/@DEBIAN_CODENAME@/$DEBIAN_CODENAME/g" \
        -e "s/@DEBIAN_MIRROR@/$DEBIAN_MIRROR/g" \
        -e "s/@INSTALL_DIR@/$install_dir/g" \
        -e "s/@SERIAL@/$serial/g" \
        -e "s/@CONSOLE_ARGS@/$console_args/g" \
        -e "s/@ARCH@/$arch/g" \
        -e "s|@PKGSEL_INCLUDE@|$pkgsel_include|g" \
        "$@"
}

# Kurulumda Debian'dan indirilecek paketler; ad denetimi Debian dizinine göre.
index=$root/downloads/Packages-$arch.xz
if [ -r "$index" ]; then
    pkgsel_include=$(python3 "$root/tools/pkglist.py" include --packages "$index")
else
    pkgsel_include=$(python3 "$root/tools/pkglist.py" include)
fi

# --- preseed ve markalama initrd'ye eklenir ----------------------------------
overlay=$work/overlay
mkdir -p "$overlay"
render "$root/iso/preseed.cfg.in" > "$overlay/preseed.cfg"
if [ "$test_mode" = 1 ]; then
    {
        printf '\n'
        cat "$root/iso/preseed-test.cfg"
        printf 'd-i pkgsel/include string %s openssh-server\n' "$pkgsel_include"
        printf 'd-i preseed/late_command string sh /cdrom/orvixos/late-install.sh && sh /cdrom/orvixos/test-late.sh\n'
    } >> "$overlay/preseed.cfg"
fi
for variant in "" gtk/; do
    xorriso -osirrox on -indev "$base_iso" \
        -extract "/$install_dir/${variant}initrd.gz" "$work/initrd.orig" >/dev/null 2>&1
    mkdir -p "$work/$install_dir/$variant"
    # Dosyalar özgün initrd arşivinin içine eklenir (Debian'ın "cpio -A" yöntemi).
    python3 "$root/tools/initrd-append.py" "$work/initrd.orig" "$work/$install_dir/${variant}initrd.gz" \
        "preseed.cfg=$overlay/preseed.cfg" \
        "usr/share/graphics/logo_debian.png=$root/branding/installer-banner.png" \
        "usr/share/graphics/logo_debian_dark.png=$root/branding/installer-banner-dark.png"
    rm -f "$work/initrd.orig"
done

# --- ISO üzerindeki OrvixOS dosyaları ----------------------------------------
payload=$work/orvixos
mkdir -p "$payload/pool"
cp "$debs"/*.deb "$payload/pool/"
cp "$root/iso/choose-browser.sh" "$root/iso/late-install.sh" "$root/iso/orvixos.templates" "$payload/"
cp "$root/LICENSE" "$payload/LICENSE.txt"
cp "$root/SOURCES.md" "$payload/SOURCES.md"
if [ "$test_mode" = 1 ]; then
    # ORVIXOS_TEST_BROWSER verilirse tarayıcı sorusu atlanır.
    if [ -n "${ORVIXOS_TEST_BROWSER:-}" ]; then
        printf '%s\n' "$ORVIXOS_TEST_BROWSER" > "$payload/browser.default"
    fi
    cp "$root/tests/test-late.sh" "$payload/test-late.sh"
    cp "$root/build/test/id_ed25519.pub" "$payload/test-authorized_keys"
fi

if [ "$test_mode" = 1 ]; then
    render "$root/iso/grub-test.cfg.in" > "$work/grub.cfg"
else
    render "$root/iso/grub.cfg.in" > "$work/grub.cfg"
fi
printf 'OrvixOS %s "%s" - Debian %s tabanlı %s NETINST\n' \
    "$ORVIXOS_VERSION" "$ORVIXOS_CODENAME" "$DEBIAN_VERSION" "$arch" > "$work/disk-info"

set -- \
    -indev "$base_iso" -outdev "$output_iso" \
    -volid "OrvixOS $ORVIXOS_VERSION $arch" \
    -map "$work/grub.cfg" /boot/grub/grub.cfg \
    -map "$work/disk-info" /.disk/info \
    -map "$work/$install_dir/initrd.gz" "/$install_dir/initrd.gz" \
    -map "$work/$install_dir/gtk/initrd.gz" "/$install_dir/gtk/initrd.gz" \
    -map "$payload" /orvixos

if [ "$arch" = amd64 ]; then
    render "$root/iso/isolinux.cfg.in" > "$work/isolinux.cfg"
    set -- "$@" \
        -map "$work/isolinux.cfg" /isolinux/isolinux.cfg \
        -map "$root/branding/isolinux-splash.png" /isolinux/splash.png
fi

mkdir -p "$(dirname "$output_iso")"
rm -f "$output_iso"
xorriso "$@" -boot_image any replay 2>&1 | grep -E 'FAILURE|SORRY|Writing to' || true
[ -s "$output_iso" ] || { printf 'ISO üretilemedi.\n' >&2; exit 1; }

(cd "$(dirname "$output_iso")" && shasum -a 256 "$(basename "$output_iso")" > "$(basename "$output_iso").sha256")
printf 'OrvixOS ISO hazır: %s\n' "$output_iso"
