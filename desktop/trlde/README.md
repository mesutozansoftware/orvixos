# TRLDE

**TRLDE (Turkish Linux Desktop Environment)**, Wayland tabanlı hafif bir Linux
masaüstü ortamıdır. Bu kopya **OrvixOS** için Debian 13 (trixie) üzerine
uyarlanmıştır ve OrvixOS'un varsayılan masaüstüdür; ARM64 ve x86_64 sistemlerde
çalışır.

Bu depo çalışan bir `0.4.0` masaüstü oturumu sağlar:

- pencere yönetimi ve Wayland compositor için **labwc**,
- panel ve görev çubuğu için TRLDE temalı **Waybar**,
- kategoriler, Türkçe arama ve güç düğmeleri içeren TRLDE uygulama menüsü,
- bildirimler için **Mako**,
- duvar kâğıdı için **swaybg**.

TRLDE ayrıca kendi hızlı ayarlar, görünüm, bildirim merkezi, yazılım merkezi,
pano geçmişi, ekran kaydı, yedekleme, ekran profilleri, kilit ekranı ve güç
arayüzlerini içerir. Dört çalışma alanı, pencere döşeme, sistem tepsisi ve GDM /
Plymouth markalaması bütünleşiktir. Düğmeler NetworkManager, BlueZ,
PipeWire, brightnessctl, Flatpak ve systemd ile doğrudan sistem işlevlerini
denetler.

Bu, tek başına yazılmış yeni bir compositor değil; labwc etrafında bütünleşmiş
gerçek bir Linux masaüstü ortamıdır. İlerleyen sürümlerde altyapı bileşenleri,
oturum biçimi değişmeden TRLDE'ye özgü karşılıklarla değiştirilebilir.

## Kurulum

TRLDE, OrvixOS ISO'su ile birlikte gelir. Var olan bir Debian 13 sistemine
OrvixOS deposundaki paketle kurulabilir:

```bash
vpx install ./trlde_0.4.0-1orvixos1_all.deb
```

Paket gerekli Debian bağımlılıklarını (labwc, Waybar, Wofi, Mako, swaybg, foot,
PipeWire, NetworkManager ...) Debian sunucularından kurar. Giriş ekranında
**TRLDE** oturumu seçilir.

Kurulumu kontrol etmek için:

```bash
./scripts/doctor.sh
```

## Kısayollar

| Kısayol | İşlev |
|---|---|
| `Super + Space` | Uygulama menüsü |
| `Super + A` | Hızlı ayarlar |
| `Super + V` | Pano geçmişi |
| `Super + Shift + R` | Ekran kaydı |
| `Super + Shift + B` | Yedekleme |
| `Super + L` | Ekranı kilitle |
| `Super + P` | Güç menüsü |
| `Super + Tab` | Açık pencere listesi |
| `Super + 1…4` | Çalışma alanına geç |
| `Super + Shift + 1…4` | Pencereyi çalışma alanına taşı |
| `Super + Enter` | Terminal |
| `Super + Q` | Aktif pencereyi kapat |
| `Super + F` | Tam ekran |
| `Super + Sol/Sağ` | Pencereyi ekranın yarısına yerleştir |
| `Super + Shift + Sol/Sağ` | Pencereyi üst köşeye döşe |
| `Super + Ctrl + Sol/Sağ` | Pencereyi alt köşeye döşe |
| `Alt + Tab` | Pencereler arasında geçiş |
| `Super + Shift + E` | TRLDE oturumunu kapat |

## Geliştirme

```bash
make check
make install DESTDIR="$PWD/build/root"
```

Debian paketi OrvixOS kök dizinindeki `scripts/build-debs.sh` ile üretilir.

## Dizinler

```text
bin/          oturum ve başlangıç betikleri
labwc/        compositor ve klavye yapılandırması
waybar/       panel yapılandırması ve teması
wofi/         uygulama menüsü teması
mako/         bildirim teması
wallpapers/   TRLDE duvar kâğıtları
sessions/     Wayland oturum tanımı
scripts/      kurulum ve tanılama araçları
tests/        yerel doğrulamalar
docs/         sürüm notları
```

## Lisans

MIT
