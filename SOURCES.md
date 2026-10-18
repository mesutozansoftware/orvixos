# OrvixOS kaynak kodu ve lisanslar

OrvixOS ISO'su özgür yazılımlardan oluşur. Bu belge, ISO'daki her bileşenin
kaynak koduna nereden ulaşılabileceğini gösterir. GNU GPL ve benzeri
lisansların gerektirdiği kaynak kodu erişimi bu kaynaklarla sağlanır.

## OrvixOS'un kendi bileşenleri

| Bileşen | Lisans | Kaynak |
|---|---|---|
| vpx (paket yöneticisi) | MIT | bu depo: `packages/vpx/` |
| orvixos-base, orvixos-desktop | MIT | bu depo: `packages/` |
| TRLDE masaüstü ortamı | MIT | bu depo: `desktop/trlde/` |
| Kurulum yapılandırması (preseed, menüler, betikler) | MIT | bu depo: `iso/`, `scripts/` |
| Markalama (logo, açılış ekranı) | MIT | bu depo: `branding/` |
| Vira Browser | MIT | Vira Browser projesi (https://virabrowser.vercel.app) |
| Inter yazı tipi (yalnızca logo görsellerinde) | SIL OFL 1.1 | https://github.com/rsms/inter, `branding/fonts/Inter-OFL.txt` |

## Debian bileşenleri

ISO, Debian 13.7.0 netinst kalıbının değiştirilmiş hâlidir. Linux
çekirdeği, debian-installer, GRUB ve ISO'daki tüm `.deb` paketleri Debian
projesinindir ve kendi lisanslarıyla (çoğunlukla GPL) dağıtılır.

- Değişiklikler: debian-installer initrd'sine yalnızca `preseed.cfg` ve iki
  logo görseli eklendi; önyükleme menüleri değiştirildi. Bu dosyaların tamamı
  bu depodadır (`iso/`, `branding/`). Debian'ın hiçbir ikili dosyası
  değiştirilmedi.
- Kaynak kodu: https://deb.debian.org/debian/pool/ (her paketin kaynağı,
  `vpx source <paket>` ya da `apt-get source <paket>` ile de alınabilir)
- Belirli bir sürümün birebir kaynağı: https://snapshot.debian.org/
- Debian kaynak DVD/BD kalıpları: https://cdimage.debian.org/debian-cd/current/source/

Kurulum sırasında indirilen paketler doğrudan Debian sunucularından gelir.

## Electron ve Chromium (Vira Browser içinde)

- Electron 43.2.0 — MIT: https://github.com/electron/electron/tree/v43.2.0
- Chromium bileşenlerinin lisansları kurulu sistemde
  `/usr/lib/vira-browser/LICENSES.chromium.html` dosyasındadır.
- FFmpeg: Electron'un yalnızca özgür kodekler içeren `libffmpeg.so` sürümü
  kullanılır (LGPL 2.1+). Kaynak: https://github.com/electron/electron/releases/tag/v43.2.0

## Ad ve markalar

"Debian" Software in the Public Interest, Inc.'in tescilli markasıdır.
OrvixOS bağımsız bir projedir; Debian projesi tarafından desteklenmez veya
onaylanmaz.
