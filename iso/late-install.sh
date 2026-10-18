#!/bin/sh
# OrvixOS kurulumunun son adımı (preseed/late_command). debian-installer
# ortamında çalışır; hedef sistem /target altındadır. İlerleme, kurulum
# programının kendi ilerleme çubuğunda gösterilir.

set -e

. /usr/share/debconf/confmodule

log() { logger -t orvixos "$*"; }

debconf-loadtemplate orvixos /cdrom/orvixos/orvixos.templates
# debconf-apt-progress'in metinleri (pkgsel de aynısını yükler).
apt_progress_templates=/target/usr/share/debconf/templates/debconf-apt-progress.templates
[ -r "$apt_progress_templates" ] && debconf-loadtemplate debconf "$apt_progress_templates" || true

db_progress START 0 100 orvixos/progress/title
db_progress INFO orvixos/progress/prepare

browser=vira
[ -r /tmp/orvixos-browser ] && read -r browser < /tmp/orvixos-browser
mkdir -p /target/etc/orvixos
printf '%s\n' "$browser" > /target/etc/orvixos/browser

pool=/target/var/cache/orvixos
mkdir -p "$pool"
for deb in /cdrom/orvixos/pool/*.deb; do
    case "$(basename "$deb")" in
        vira-browser_*) [ "$browser" = vira ] || continue ;;
    esac
    cp "$deb" "$pool/"
done
log "OrvixOS paketleri kuruluyor (tarayıcı: $browser)"
db_progress SET 5

# Giriş ekranı (SDDM) önerileri olmadan kurulur; ardından OrvixOS paketleri
# Debian bağımlılıklarıyla birlikte kurulur.
db_progress INFO orvixos/progress/login
in-target sh -c 'DEBIAN_FRONTEND=passthrough debconf-apt-progress --from 5 --to 55 --logstderr -- \
    apt-get -q -y -o APT::Install-Recommends=false install sddm qml6-module-qtquick-controls qml6-module-qtquick-layouts zenity'

db_progress INFO orvixos/progress/desktop
in-target sh -c 'DEBIAN_FRONTEND=passthrough debconf-apt-progress --from 55 --to 95 --logstderr -- \
    apt-get -q -y install /var/cache/orvixos/*.deb'

db_progress INFO orvixos/progress/finish
in-target sh -c 'rm -rf /var/cache/orvixos; systemctl set-default graphical.target'
db_progress SET 100
db_progress STOP
log "OrvixOS kurulumu tamamlandı"
