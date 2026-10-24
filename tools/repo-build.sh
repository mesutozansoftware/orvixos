#!/bin/sh
# OrvixOS paket deposunu (düz APT deposu) oluşturur, imzalar ve GitHub'daki
# "packages" sürümüne yükler. Site /repo/ isteklerini oraya yönlendirir
# (site/vercel.json): https://orvixos.is-a.dev/repo, https://orvixos.vercel.app/repo
#
# İmza anahtarı ilk çalıştırmada üretilir: gizli anahtar build/repo-key/
# altında kalır (git'e girmez, YEDEKLE); açık anahtar orvixos-base paketine girer.
#
# Not: vm() komutları tests/vm.sh ile tek tırnak içinde çalışır; içlerinde
# tek tırnak kullanılmaz.
#
# Kullanım: tools/repo-build.sh [--no-upload]
#   Önce: scripts/build-debs.sh arm64 amd64 ve tools/repo-debs.sh

set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
key_dir=build/repo-key
secret=$key_dir/orvixos-repo.sec.asc
keyring=packages/orvixos-base/root/usr/share/keyrings/orvixos-archive-keyring.gpg
repo=build/repo
remote=/srv/orvixos-repo
ssh_opts="-q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
to_vm() { scp $ssh_opts -i build/test/id_ed25519 -P 2222 "$@"; }
vm() { sh tests/vm.sh "$*"; }

vm "command -v apt-ftparchive >/dev/null || DEBIAN_FRONTEND=noninteractive apt-get -qq -y install apt-utils >/dev/null; rm -rf $remote; mkdir -p $remote/pool $remote/gnupg; chmod 777 $remote $remote/pool; chmod 700 $remote/gnupg"

if [ ! -f "$secret" ]; then
    echo "==> İmza anahtarı üretiliyor"
    mkdir -p "$key_dir"
    chmod 700 "$key_dir"
    vm "GNUPGHOME=$remote/gnupg gpg --batch --passphrase \"\" --quick-gen-key \"OrvixOS Archive Signing Key\" ed25519 sign never && GNUPGHOME=$remote/gnupg gpg --batch --armor --export-secret-keys > $remote/secret.asc && chmod 644 $remote/secret.asc"
    scp $ssh_opts -i build/test/id_ed25519 -P 2222 "orvix@127.0.0.1:$remote/secret.asc" "$secret"
    chmod 600 "$secret"
else
    to_vm "$secret" "orvix@127.0.0.1:$remote/pool/.key.asc"
    vm "GNUPGHOME=$remote/gnupg gpg --batch --import $remote/pool/.key.asc && rm -f $remote/pool/.key.asc"
fi
mkdir -p "$(dirname "$keyring")"
vm "GNUPGHOME=$remote/gnupg gpg --batch --export > $remote/keyring.gpg; chmod 644 $remote/keyring.gpg; rm -f $remote/secret.asc"
scp $ssh_opts -i build/test/id_ed25519 -P 2222 "orvix@127.0.0.1:$remote/keyring.gpg" "$keyring"

echo "==> Paketler toplanıyor"
rm -rf "$repo"
mkdir -p "$repo"
for deb in build/debs/arm64/*.deb build/debs/amd64/*.deb build/repo-extra/*.deb; do
    [ -f "$deb" ] && cp "$deb" "$repo/"
done
ls "$repo"
to_vm "$repo"/*.deb "orvix@127.0.0.1:$remote/pool/"

echo "==> Depo dizini ve imzalar"
vm "cd $remote/pool && apt-ftparchive packages . > Packages && gzip -9kf Packages && xz -kf Packages && \
apt-ftparchive -o APT::FTPArchive::Release::Origin=OrvixOS -o APT::FTPArchive::Release::Label=OrvixOS \
 -o APT::FTPArchive::Release::Suite=stable -o APT::FTPArchive::Release::Codename=nova \
 -o APT::FTPArchive::Release::Description=OrvixOS release . > Release && \
GNUPGHOME=$remote/gnupg gpg --batch --yes --clearsign -o InRelease Release && \
GNUPGHOME=$remote/gnupg gpg --batch --yes -abs -o Release.gpg Release && chmod 644 *"
for file in Packages Packages.gz Packages.xz Release InRelease Release.gpg; do
    scp $ssh_opts -i build/test/id_ed25519 -P 2222 "orvix@127.0.0.1:$remote/pool/$file" "$repo/$file"
done
vm "rm -rf $remote"
grep -c '^Package:' "$repo/Packages" | sed 's/^/Paket sayısı: /'

[ "${1:-}" = --no-upload ] && exit 0

echo "==> GitHub'a yükleniyor (sürüm: packages)"
repo_slug=mesutozansoftware/orvixos
if ! gh release view packages -R "$repo_slug" >/dev/null 2>&1; then
    gh release create packages -R "$repo_slug" --title "OrvixOS paket deposu" \
        --notes "vpx paket deposu (APT). Kaynak: https://orvixos.is-a.dev/repo ve https://orvixos.vercel.app/repo. Bu sürümü elle değiştirmeyin; tools/repo-build.sh günceller." \
        --latest=false
fi
gh release upload packages -R "$repo_slug" --clobber "$repo"/*
# Kısa indirme adresleri (/repo/PAKET) ve paket listesi sayfası
python3 tools/repo-site.py
echo "Depo hazır."
