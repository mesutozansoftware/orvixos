#!/bin/sh
# OrvixOS kurulumu: tarayıcı seçimi (partman/early_command ile çalışır).
# Seçilen tarayıcının Debian paketleri pkgsel/include listesine eklenir;
# Vira Browser OrvixOS paketi olarak late-install.sh içinde kurulur.

. /usr/share/debconf/confmodule

debconf-loadtemplate orvixos /cdrom/orvixos/orvixos.templates

if [ -r /cdrom/orvixos/browser.default ]; then
    # Otomatik test kurulumları soruyu atlar.
    read -r preset < /cdrom/orvixos/browser.default
    db_set orvixos/browser "$preset"
else
    db_input critical orvixos/browser || true
    db_go || true
fi

db_get orvixos/browser
choice=${RET:-vira}

case "$choice" in
    firefox) extra="firefox-esr firefox-esr-l10n-tr" ;;
    chromium) extra="chromium chromium-l10n" ;;
    *) choice=vira; extra="" ;;
esac

if [ -n "$extra" ]; then
    db_get pkgsel/include
    db_set pkgsel/include "$RET $extra"
fi

printf '%s\n' "$choice" > /tmp/orvixos-browser
logger -t orvixos "tarayıcı seçimi: $choice"
exit 0
