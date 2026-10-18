#!/bin/sh

set -u

status=0

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        printf '  [OK]   %s\n' "$1"
    else
        printf '  [EKSİK] %s\n' "$1"
        status=1
    fi
}

check_file() {
    if [ -r "$1" ]; then
        printf '  [OK]   %s\n' "$1"
    else
        printf '  [EKSİK] %s\n' "$1"
        status=1
    fi
}

printf 'Mimari: %s\n' "$(uname -m)"
printf '%s\n' "Komutlar:"
for command_name in labwc waybar wofi mako swaybg swaylock swayidle foot wpctl \
    nm-applet nm-connection-editor blueman-applet pavucontrol wdisplays brightnessctl; do
    check_command "$command_name"
done

printf '%s\n' "Kurulu TRLDE dosyaları:"
check_file /usr/bin/trlde-session
check_file /usr/bin/trlde-quick-settings
check_file /usr/bin/trlde-lock
check_file /usr/share/wayland-sessions/trlde.desktop
check_file /usr/share/trlde/labwc/rc.xml
check_file /usr/share/trlde/waybar/config.jsonc
check_file /usr/share/backgrounds/trlde/trlde.svg
check_file /usr/share/backgrounds/trlde/trlde-turquoise.svg
check_file /usr/share/applications/trlde-settings.desktop

if [ "$status" -eq 0 ]; then
    printf '%s\n' "TRLDE oturumu hazır görünüyor."
else
    printf '%s\n' "Bazı bileşenler eksik; 'vpx install trlde' komutunu çalıştır."
fi

exit "$status"
