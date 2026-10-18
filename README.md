# OrvixOS

**OrvixOS**, Debian 13 (trixie) tabanlı, ücretsiz ve özgür bir işletim
sistemidir. Bu depo OrvixOS'un tüm kaynaklarını ve derleme araçlarını içerir.

- **Masaüstü:** [TRLDE](desktop/trlde/) (Türkçe Linux Masaüstü Ortamı, labwc/Wayland)
- **Paket yöneticisi:** [vpx](packages/vpx/): APT tabanlıdır ve paketleri doğrudan
  Debian sunucularından indirir. `apt install` yerine `vpx install` yazılır.
- **Tarayıcı:** Kurulumda seçilir: **Vira Browser (önerilen)**, Firefox ESR ya da Chromium
- **Mimariler:** ARM64 ve x64 (Intel/AMD)
- **Site:** [site/](site/) (Vercel'de yayınlanır)

## vpx

```bash
vpx install htop        # paket kur
vpx remove htop         # paket kaldır
vpx search editör       # depoda ara
vpx sync                # update + upgrade
vpx files bash          # paketin dosyaları
vpx owner /usr/bin/ls   # dosya hangi pakette
vpx doctor              # paket veritabanını onar
```

Diğer tüm komutlar `apt`'ye iletilir. Ayrıntılar: `man vpx`.

## Başka masaüstleri

```bash
vpx install task-kde-desktop     # KDE Plasma
vpx install task-gnome-desktop   # GNOME
vpx install task-xfce-desktop    # XFCE
```

Giriş ekranındaki dişli menüsünden oturum seçilir; varsayılan oturum TRLDE'dir.

## ISO derleme

macOS'ta (Homebrew: `xorriso`) ya da Linux'ta çalışır; Docker veya dpkg gerekmez.

```bash
make fetch        # Debian ISO, Electron ve paket dizinlerini indir (SHA-256 doğrulamalı)
make iso          # paketleri ve ISO'ları üret -> outputs/
make test-iso     # soru sormayan otomatik test ISO'ları -> build/test/
```

Tek mimari için: `make iso ARCHES=arm64`.

### Nasıl çalışır?

ISO, resmî Debian netinst kalıbından üretilir:

1. `scripts/build-debs.sh`: OrvixOS paketlerini üretir (`vpx`, `trlde`,
   `orvixos-base`, `orvixos-desktop`, `vira-browser`).
2. `scripts/build-iso.sh`: debian-installer initrd'sine `preseed.cfg` ve
   OrvixOS logosunu ekler, önyükleme menülerini değiştirir ve paketleri
   `/orvixos/pool` altına koyar.
3. Kurulumda dil, kullanıcı ve disk sorulur; bölümlemeden önce tarayıcı seçimi
   (`iso/choose-browser.sh`) gelir. Masaüstü paketleri Debian sunucularından
   indirilir, sonra OrvixOS paketleri kurulur (`iso/late-install.sh`).

### Test

```bash
make test-iso ARCHES=arm64
ARCH=arm64 tests/qemu-run.sh install build/test/OrvixOS-1.0.0-arm64-test.iso
ARCH=arm64 tests/qemu-run.sh boot      # SSH: ssh -p 2222 -i build/test/id_ed25519 orvix@127.0.0.1
```

## Dizinler

```text
orvixos.conf   sürüm bilgileri
packages/      OrvixOS Debian paketleri (vpx, orvixos-base, orvixos-desktop, trlde, vira-browser)
desktop/trlde  TRLDE masaüstü kaynağı (Debian uyarlaması)
iso/           kurulum yapılandırması (preseed, menüler, kurulum betikleri)
branding/      logo, kurulum ve açılış görselleri (Inter, SIL OFL)
vendor/        Vira Browser uygulaması
scripts/       indirme ve derleme betikleri
tools/         .deb ve initrd araçları
tests/         QEMU test araçları
site/          OrvixOS web sitesi
```

## Lisans

OrvixOS'un kendi dosyaları MIT lisanslıdır ([LICENSE](LICENSE)). ISO'daki Debian
bileşenlerinin lisansları ve kaynak kodu bağlantıları: [SOURCES.md](SOURCES.md).
OrvixOS bağımsız bir projedir; Debian projesi tarafından desteklenmez veya onaylanmaz.
