#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_root=$(mktemp -d)
trap 'rm -rf "$temporary_root"' EXIT HUP INT TERM

cd "$project_root"

sh -n bin/trlde-session
sh -n bin/trlde-autostart
sh -n bin/trlde-launcher
sh -n bin/trlde-lock
sh -n bin/trlde-power
sh -n bin/trlde-wallpaper
sh -n bin/trlde-run
sh -n bin/trlde-screenshot
sh -n bin/trlde-doctor
sh -n bin/trlde-update-refresh
sh -n bin/trlde-update-install
sh -n bin/trlde-bluetooth
sh -n bin/trlde-brightness
sh -n bin/trlde-clipboard-watch
sh -n labwc/autostart
sh -n scripts/doctor.sh

python3 -m json.tool waybar/config.jsonc >/dev/null

python3 - <<'PY'
import xml.etree.ElementTree as ET
from pathlib import Path

ET.parse("labwc/rc.xml")
for svg in Path("wallpapers").glob("*.svg"):
    ET.parse(svg)
ET.parse("branding/trlde-logo.svg")

for program in (
    "bin/trlde-quick-settings",
    "bin/trlde-update",
    "bin/trlde-wifi",
    "bin/trlde-gestures",
    "bin/orvix-welcome",
    "bin/trlde-appearance",
    "bin/trlde-notifications",
    "bin/trlde-about",
    "bin/trlde-settings",
    "bin/trlde-welcome",
    "bin/trlde-drawer",
    "bin/trlde-software",
    "bin/trlde-clipboard",
    "bin/trlde-recorder",
    "bin/trlde-backup",
    "bin/trlde-input",
    "bin/trlde-display-profiles",
):
    compile(Path(program).read_text(encoding="utf-8"), program, "exec")
PY

make install DESTDIR="$temporary_root" >/dev/null

for installed_file in \
    /usr/bin/trlde-session \
    /usr/bin/trlde-launcher \
    /usr/bin/trlde-drawer \
    /usr/bin/trlde-lock \
    /usr/bin/trlde-power \
    /usr/bin/trlde-wallpaper \
    /usr/bin/trlde-quick-settings \
    /usr/bin/trlde-appearance \
    /usr/bin/trlde-notifications \
    /usr/bin/trlde-about \
    /usr/bin/trlde-settings \
    /usr/bin/trlde-welcome \
    /usr/bin/trlde-run \
    /usr/bin/trlde-screenshot \
    /usr/bin/trlde-doctor \
    /usr/bin/trlde-update \
    /usr/bin/trlde-bluetooth \
    /usr/bin/trlde-brightness \
    /usr/bin/trlde-software \
    /usr/bin/trlde-clipboard \
    /usr/bin/trlde-recorder \
    /usr/bin/trlde-backup \
    /usr/bin/trlde-input \
    /usr/bin/trlde-display-profiles \
    /usr/libexec/trlde/trlde-autostart \
    /usr/libexec/trlde/trlde-clipboard-watch \
    /usr/share/wayland-sessions/trlde.desktop \
    /usr/share/trlde/labwc/rc.xml \
    /usr/share/trlde/waybar/config.jsonc \
    /usr/share/themes/TRLDE/labwc/themerc \
    /usr/share/xdg-desktop-portal/trlde-portals.conf \
    /usr/lib/tmpfiles.d/trlde-x11.conf \
    /usr/lib/systemd/user/trlde-session.target \
    /usr/lib/systemd/user/trlde-update.service \
    /usr/lib/systemd/user/trlde-update.timer \
    /usr/lib/systemd/user/trlde-clipboard.service \
    /usr/share/backgrounds/trlde/trlde.svg; do
    test -r "$temporary_root$installed_file"
done

for installed_file in \
    /usr/share/backgrounds/trlde/trlde-turquoise.svg \
    /usr/share/backgrounds/trlde/trlde-sunset.svg \
    /usr/share/applications/trlde-settings.desktop \
    /usr/share/applications/trlde-welcome.desktop \
    /usr/share/applications/trlde-screenshot.desktop \
    /usr/share/applications/trlde-updates.desktop \
    /usr/share/applications/trlde-software.desktop \
    /usr/share/applications/trlde-clipboard.desktop \
    /usr/share/applications/trlde-recorder.desktop \
    /usr/share/applications/trlde-backup.desktop \
    /usr/share/applications/trlde-input.desktop \
    /usr/share/applications/trlde-display-profiles.desktop \
    /usr/share/pixmaps/trlde-logo.svg \
    /usr/share/plymouth/themes/trlde/trlde.plymouth \
    /etc/xdg/mako/config \
    /etc/dconf/db/gdm.d/01-trlde; do
    test -r "$temporary_root$installed_file"
done

printf '%s\n' "Tüm TRLDE kontrolleri başarılı."
