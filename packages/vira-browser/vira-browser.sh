#!/bin/sh
# Vira Browser başlatıcısı — OrvixOS'un varsayılan web tarayıcısı.
# Wayland oturumunda yerel Wayland, aksi halde X11 kullanılır.
exec /usr/lib/vira-browser/vira-browser --ozone-platform-hint=auto \
    --enable-features=WaylandWindowDecorations ${VIRA_BROWSER_FLAGS:-} "$@"
