#!/bin/sh
# OrvixOS deposunun ek paketlerini hazırlar (repo/packages.list):
# mesutozansoftware projeleri paketlenir, VSCodium/Heroic/ChestZip'in hazır
# .deb'leri indirilir. Çıktı: build/repo-extra/*.deb
#
# Kullanım: tools/repo-debs.sh

set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$root/build/repo-extra
work=$(mktemp -d /tmp/orvixos-repo.XXXXXX)
trap 'rm -rf "$work"' EXIT INT TERM
mkdir -p "$out"

say() { printf '==> %s\n' "$*"; }

control() {
    # control DİZİN PAKET SÜRÜM MİMARİ BAĞIMLILIKLAR AÇIKLAMA [AYRINTI]
    mkdir -p "$1"
    {
        printf 'Package: %s\nVersion: %s\nArchitecture: %s\n' "$2" "$3" "$4"
        printf 'Maintainer: OrvixOS Project <noreply@orvixos.invalid>\n'
        [ -n "$5" ] && printf 'Depends: %s\n' "$5"
        printf 'Section: misc\nPriority: optional\nHomepage: https://github.com/mesutozansoftware\n'
        printf 'Description: %s\n' "$6"
        [ -n "${7:-}" ] && printf ' %s\n' "$7"
    } > "$1/control"
}

doc() {
    # doc STAGE PAKET LİSANS
    mkdir -p "$1/usr/share/doc/$2"
    printf 'Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/\nUpstream-Name: %s\nSource: https://github.com/mesutozansoftware\n\nFiles: *\nCopyright: mesutozansoftware\nLicense: %s\n' \
        "$2" "$3" > "$1/usr/share/doc/$2/copyright"
}

desktop_file() {
    # desktop_file STAGE AD İSİM AÇIKLAMA KOMUT SİMGE KATEGORİLER
    mkdir -p "$1/usr/share/applications"
    printf '[Desktop Entry]\nName=%s\nComment=%s\nExec=%s\nIcon=%s\nType=Application\nCategories=%s\n' \
        "$3" "$4" "$5" "$6" "$7" > "$1/usr/share/applications/$2.desktop"
}

mkdeb() { python3 "$root/tools/mkdeb.py" --root "$1" --control "$2" --output "$3"; }

latest_asset() {
    # latest_asset SAHİP/DEPO DESEN → indirilen dosyanın yolu
    gh release download -R "$1" -p "$2" -D "$work/dl" --clobber >/dev/null
    ls -t "$work/dl"/$2 | head -n 1
}

mkdir -p "$work/dl"

# --- SubPulse (kaynak koddan, tüm mimariler) ---------------------------------
tag=$(gh release view -R mesutozansoftware/SubPulse --json tagName -q .tagName)
version=${tag#v}
say "SubPulse $version"
src=$work/subpulse-src
mkdir -p "$src"
gh api "repos/mesutozansoftware/SubPulse/tarball/$tag" > "$work/subpulse.tar.gz"
tar -xzf "$work/subpulse.tar.gz" -C "$src" --strip-components=1
stage=$work/subpulse
mkdir -p "$stage/usr/lib/subpulse/vendor" "$stage/usr/bin" "$stage/usr/share/pixmaps"
cp -R "$src/subpulse" "$src/run.py" "$stage/usr/lib/subpulse/"
[ -d "$src/data" ] && cp -R "$src/data" "$stage/usr/lib/subpulse/"
[ -d "$src/assets" ] && cp -R "$src/assets" "$stage/usr/lib/subpulse/"
[ -f "$src/assets/icon.png" ] && cp "$src/assets/icon.png" "$stage/usr/share/pixmaps/subpulse.png"
# Debian'da olmayan saf Python bağımlılıkları pakete gömülür.
python3 -m pip download --quiet --no-deps --only-binary=:all: --dest "$work/wheels" customtkinter darkdetect
for wheel in "$work/wheels"/*.whl; do
    (cd "$stage/usr/lib/subpulse/vendor" && unzip -q -o "$wheel")
done
find "$stage" -name '__pycache__' -prune -exec rm -rf {} +
cat > "$stage/usr/bin/subpulse" <<'EOF'
#!/bin/sh
export PYTHONPATH=/usr/lib/subpulse/vendor${PYTHONPATH:+:$PYTHONPATH}
exec python3 /usr/lib/subpulse/run.py "$@"
EOF
chmod 755 "$stage/usr/bin/subpulse"
desktop_file "$stage" subpulse "SubPulse" "Alan adı keşfi ve HTTP yoklama aracı" subpulse subpulse "Network;Security;"
doc "$stage" subpulse MIT
control "$work/subpulse-control" subpulse "$version" all \
    "python3 (>= 3.9), python3-tk, python3-aiohttp, python3-dnspython, python3-bs4, python3-packaging" \
    "Fast subdomain discovery and HTTP probing suite" "SubPulse by mesutozansoftware (GUI and CLI)."
mkdeb "$stage" "$work/subpulse-control" "$out/subpulse_${version}_all.deb"

# --- PyBench (Linux x64 programı) ----------------------------------------------
tag=$(gh release view -R mesutozansoftware/pybench --json tagName -q .tagName)
version=${tag#v}
say "PyBench $version"
archive=$(latest_asset mesutozansoftware/pybench 'PyBench-linux-x64.tar.gz')
stage=$work/pybench
mkdir -p "$stage/usr/lib/pybench" "$stage/usr/bin"
tar -xzf "$archive" -C "$stage/usr/lib/pybench"
chmod 755 "$stage/usr/lib/pybench/PyBench"
ln -s ../lib/pybench/PyBench "$stage/usr/bin/pybench"
desktop_file "$stage" pybench "PyBench" "Bilgisayar performans testi (CPU, GPU, RAM, depolama)" pybench utilities-system-monitor "System;Monitor;"
doc "$stage" pybench "Proprietary (mesutozansoftware, redistributed with permission)"
control "$work/pybench-control" pybench "$version" amd64 "" \
    "Computer benchmark (CPU, GPU, RAM, storage)" "PyBench by mesutozansoftware."
mkdeb "$stage" "$work/pybench-control" "$out/pybench_${version}_amd64.deb"

# --- nanolimiter (Linux x64 programı) --------------------------------------
say "nanolimiter"
archive=$(latest_asset mesutozansoftware/nanolimiter '*.zip')
stage=$work/nanolimiter
mkdir -p "$stage/usr/bin" "$stage/usr/share/doc/nanolimiter"
(cd "$work" && unzip -q -o "$archive" nanolimiter-linux README.md)
install -m 755 "$work/nanolimiter-linux" "$stage/usr/bin/nanolimiter"
doc "$stage" nanolimiter MIT
cp "$work/README.md" "$stage/usr/share/doc/nanolimiter/README.md"
control "$work/nanolimiter-control" nanolimiter 1.0 amd64 "" \
    "Low-memory HTTP reverse proxy and rate limiter" "nanolimiter by mesutozansoftware."
mkdeb "$stage" "$work/nanolimiter-control" "$out/nanolimiter_1.0_amd64.deb"

# --- Hazır .deb'ler -----------------------------------------------------------
say "ChestZip"
cp "$(latest_asset mesutozansoftware/chestzip 'chestzip_*_amd64.deb')" "$out/"
say "VSCodium"
cp "$(latest_asset VSCodium/vscodium 'codium_*_amd64.deb')" "$out/"
cp "$(latest_asset VSCodium/vscodium 'codium_*_arm64.deb')" "$out/"
say "Heroic Games Launcher"
heroic=$(latest_asset Heroic-Games-Launcher/HeroicGamesLauncher 'Heroic-*-linux-amd64.deb')
cp "$heroic" "$out/heroic_$(basename "$heroic" | sed 's/^Heroic-//; s/-linux-amd64.deb$//')_amd64.deb"

ls -la "$out"
