#!/bin/sh
# OrvixOS kurulumunun son adımı (preseed/late_command). debian-installer
# ortamında çalışır; hedef sistem /target altındadır.

set -e

log() { logger -t orvixos "$*"; }

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

# gdm3'ün önerileri GNOME oturumunu çekmesin diye önerisiz kurulur;
# ardından OrvixOS paketleri Debian bağımlılıklarıyla birlikte kurulur.
in-target sh -c '
    set -e
    export DEBIAN_FRONTEND=noninteractive
    apt-get -y -q --no-install-recommends install gdm3 zenity
    apt-get -y -q install /var/cache/orvixos/*.deb
    rm -rf /var/cache/orvixos
    systemctl set-default graphical.target
'
log "OrvixOS kurulumu tamamlandı"
