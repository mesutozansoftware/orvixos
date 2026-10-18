# OrvixOS — Nasıl yapılır? (Türkçe kılavuz)

Bu belge, Claude olmadan da OrvixOS'u derleyip yayınlayabilmen içindir.
Tüm komutlar proje klasöründe çalıştırılır:

```bash
cd "/Volumes/240GB SSD/ApexOS"
```

## 1. Tek komutla her şey

```bash
sh scripts/release.sh
```

Bu komut sırasıyla şunları yapar:

1. Derleme sanal makinesini açar (kapalıysa).
2. OrvixOS paketlerini üretir (vpx, trlde, vira-browser, orvixos-base, orvixos-desktop).
3. ARM64 ve x64 canlı ISO'larını derler (ARM64 ~15 dk, x64 ~40 dk).
4. ISO'ları GitHub'daki v1.0.0 sürümüne yükler.
5. Sitedeki SHA-256 ve boyutları günceller, siteyi Vercel'de yayınlar.
6. Değişiklikleri GitHub'a gönderir.

Seçenekler:

| Komut | Ne yapar |
|---|---|
| `sh scripts/release.sh arm64` | Yalnızca ARM64 |
| `SKIP_BUILD=1 sh scripts/release.sh` | Derlemeden, `outputs/` içindeki ISO'ları yükle + siteyi güncelle |
| `SKIP_SITE=1 sh scripts/release.sh` | Siteye dokunma |

**Yarım kalan bir derlemeyi bitirmek:** `outputs/` klasöründe
`OrvixOS-1.0.0-live-arm64.iso` ve `...-live-amd64.iso` (ve `.sha256`
dosyaları) varsa yalnızca yayınlamak için:

```bash
SKIP_BUILD=1 sh scripts/release.sh
```

## 2. Gerekenler (bir kez)

```bash
brew install qemu xorriso gh node
gh auth login                    # GitHub hesabı (mesutozansoftware)
npx vercel@48.10.0 login         # Vercel hesabı (açılan bağlantıyı onayla)
```

## 3. Derleme sanal makinesi

Canlı ISO'lar `live-build` ile üretilir; bu araç yalnızca Debian'da çalıştığı
için derleme, Mac'te QEMU ile çalışan küçük bir Debian/OrvixOS sanal
makinesinde yapılır.

| | |
|---|---|
| Disk | `build/test/disk-arm64.qcow2` |
| Açmak (ekransız) | `HEADLESS=1 ARCH=arm64 sh tests/qemu-run.sh boot &` |
| Ekranlı açmak | `ARCH=arm64 sh tests/qemu-run.sh boot` |
| İçinde root komutu | `sh tests/vm.sh 'komut'` |
| SSH | `ssh -i build/test/id_ed25519 -p 2222 orvix@127.0.0.1` |
| Kullanıcı / şifre | `orvix` / `orvixtest` (yalnızca bu test makinesi) |

`release.sh` makineyi kendisi açar. Kapatmak için: `sh tests/vm.sh poweroff`.

### Derleme makinesini sıfırdan kurmak (disk silinirse)

```bash
make fetch                                  # Debian ISO, Electron vb. indir
make test-iso ARCHES=arm64                  # soru sormayan test ISO'su
ARCH=arm64 sh tests/qemu-run.sh install build/test/OrvixOS-1.0.0-arm64-test.iso
```

Kurulum ~8 dakikada biter ve makine kapanır. Ardından bir kez:

```bash
HEADLESS=1 ARCH=arm64 sh tests/qemu-run.sh boot &
sh tests/vm.sh 'apt-get update && apt-get -y install live-build squashfs-tools xorriso mtools dosfstools qemu-user-static binfmt-support'
```

## 4. Sık yapılan değişiklikler

| Ne | Dosya |
|---|---|
| Görev çubuğu (modüller) | `desktop/trlde/waybar/config.jsonc` |
| Görev çubuğu (renkler) | `desktop/trlde/waybar/style.css` |
| Sağ tık menüsü | `desktop/trlde/labwc/menu.xml` |
| Menü ikonları (SVG) | `desktop/trlde/icons/OrvixOS/scalable/actions/` |
| Kısayollar | `desktop/trlde/labwc/rc.xml` |
| Duvar kâğıdı | `desktop/trlde/wallpapers/orvixos.svg` |
| Giriş ekranı (SDDM teması) | `packages/orvixos-desktop/root/usr/share/sddm/themes/orvixos/Main.qml` |
| Kurulum programı (Calamares) | `live/config/includes.chroot/etc/calamares/` |
| Kurulu gelen uygulamalar | `packages/trlde/DEBIAN/control` (Depends / Recommends) |
| Canlı ISO'ya eklenen paketler | `scripts/build-live.sh` (Paket listeleri bölümü) |
| vpx | `packages/vpx/vpx` |
| Sürüm numarası | `orvixos.conf` |
| Web sitesi | `site/index.html` (TR metinler HTML'de, EN metinler alttaki sözlükte) |

Değişiklikten sonra `sh scripts/release.sh` yeterli.

**Yalnızca siteyi yayınlamak:**

```bash
cd site && npx -y vercel@48.10.0 deploy --prod --yes
```

## 5. Sorun giderme

| Belirti | Çözüm |
|---|---|
| Derleme çok yavaş, paketler tek tek iniyor | Sanal makinede DNS: `release.sh` bunu düzeltir. Elle: `sh tests/vm.sh 'echo "options single-request-reopen" >> /etc/resolv.conf'` |
| `No space left on device` | Mac'in ana diski dolu. Büyük dosyaları SSD'ye taşı; derleme dosyaları zaten SSD'de |
| Sanal makinede yer kalmadı | `sh tests/vm.sh 'rm -rf /srv/orvixos-live/work-* /srv/orvixos-live/*.iso'` |
| Vercel `No existing credentials` | `npx vercel@48.10.0 login` |
| GitHub yükleme hatası | `gh auth login` |
| x64 derlemesi "grub-pc Conflicts grub-efi-amd64" | `scripts/build-live.sh` güncel değil; grub-pc ayrı .deb olarak eklenmeli (bu sürümde düzeltildi) |
| Canlı ISO şifre soruyor | Şifre `live`. Normalde otomatik giriş yapar (`live/config/includes.chroot/usr/lib/live/config/0086-orvixos-sddm`) |
| Sanal makinede siyah bloklar | TRLDE sanal makinede `WLR_RENDERER=pixman` kullanır (`desktop/trlde/bin/trlde-session`) |

## 6. Bağlantılar

- İndirmeler: https://github.com/mesutozansoftware/orvixos/releases/tag/v1.0.0
- Site: https://orvixos.vercel.app
- Kaynak kodu: https://github.com/mesutozansoftware/orvixos
- Ayrıntılı teknik bilgi: `README.md`, lisanslar: `SOURCES.md`
