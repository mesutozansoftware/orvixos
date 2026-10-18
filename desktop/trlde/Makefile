PREFIX ?= /usr
SYSCONFDIR ?= /etc
DATADIR ?= $(PREFIX)/share
LIBEXECDIR ?= $(PREFIX)/libexec/trlde
TMPFILESDIR ?= $(PREFIX)/lib/tmpfiles.d
SYSTEMDUSERDIR ?= $(PREFIX)/lib/systemd/user

.PHONY: all check install uninstall

all:
	@echo "TRLDE yapılandırma tabanlı bir projedir; derleme gerekmiyor."

check:
	./tests/check.sh

install:
	install -d $(DESTDIR)$(PREFIX)/bin
	install -d $(DESTDIR)$(LIBEXECDIR)
	install -d $(DESTDIR)$(DATADIR)/wayland-sessions
	install -d $(DESTDIR)$(DATADIR)/applications
	install -d $(DESTDIR)$(DATADIR)/pixmaps
	install -d $(DESTDIR)$(DATADIR)/trlde/labwc
	install -d $(DESTDIR)$(DATADIR)/trlde/waybar
	install -d $(DESTDIR)$(DATADIR)/trlde/wofi
	install -d $(DESTDIR)$(DATADIR)/trlde/mako
	install -d $(DESTDIR)$(DATADIR)/backgrounds/trlde
	install -d $(DESTDIR)$(DATADIR)/themes/TRLDE/labwc
	install -d $(DESTDIR)$(DATADIR)/plymouth/themes/trlde
	install -d $(DESTDIR)$(DATADIR)/xdg-desktop-portal
	install -d $(DESTDIR)$(SYSCONFDIR)/xdg/mako
	install -d $(DESTDIR)$(SYSCONFDIR)/dconf/db/gdm.d
	install -d $(DESTDIR)$(TMPFILESDIR)
	install -d $(DESTDIR)$(SYSTEMDUSERDIR)
	install -m 755 bin/trlde-session $(DESTDIR)$(PREFIX)/bin/trlde-session
	install -m 755 bin/trlde-launcher $(DESTDIR)$(PREFIX)/bin/trlde-launcher
	install -m 755 bin/trlde-drawer $(DESTDIR)$(PREFIX)/bin/trlde-drawer
	install -m 755 bin/trlde-lock $(DESTDIR)$(PREFIX)/bin/trlde-lock
	install -m 755 bin/trlde-power $(DESTDIR)$(PREFIX)/bin/trlde-power
	install -m 755 bin/trlde-wallpaper $(DESTDIR)$(PREFIX)/bin/trlde-wallpaper
	install -m 755 bin/trlde-quick-settings $(DESTDIR)$(PREFIX)/bin/trlde-quick-settings
	install -m 755 bin/trlde-appearance $(DESTDIR)$(PREFIX)/bin/trlde-appearance
	install -m 755 bin/trlde-notifications $(DESTDIR)$(PREFIX)/bin/trlde-notifications
	install -m 755 bin/trlde-about $(DESTDIR)$(PREFIX)/bin/trlde-about
	install -m 755 bin/trlde-settings $(DESTDIR)$(PREFIX)/bin/trlde-settings
	install -m 755 bin/trlde-welcome $(DESTDIR)$(PREFIX)/bin/trlde-welcome
	install -m 755 bin/trlde-run $(DESTDIR)$(PREFIX)/bin/trlde-run
	install -m 755 bin/trlde-screenshot $(DESTDIR)$(PREFIX)/bin/trlde-screenshot
	install -m 755 bin/trlde-doctor $(DESTDIR)$(PREFIX)/bin/trlde-doctor
	install -m 755 bin/trlde-update $(DESTDIR)$(PREFIX)/bin/trlde-update
	install -m 755 bin/trlde-bluetooth $(DESTDIR)$(PREFIX)/bin/trlde-bluetooth
	install -m 755 bin/trlde-brightness $(DESTDIR)$(PREFIX)/bin/trlde-brightness
	install -m 755 bin/trlde-software $(DESTDIR)$(PREFIX)/bin/trlde-software
	install -m 755 bin/trlde-clipboard $(DESTDIR)$(PREFIX)/bin/trlde-clipboard
	install -m 755 bin/trlde-recorder $(DESTDIR)$(PREFIX)/bin/trlde-recorder
	install -m 755 bin/trlde-backup $(DESTDIR)$(PREFIX)/bin/trlde-backup
	install -m 755 bin/trlde-input $(DESTDIR)$(PREFIX)/bin/trlde-input
	install -m 755 bin/trlde-display-profiles $(DESTDIR)$(PREFIX)/bin/trlde-display-profiles
	install -m 755 bin/trlde-autostart $(DESTDIR)$(LIBEXECDIR)/trlde-autostart
	install -m 755 bin/trlde-clipboard-watch $(DESTDIR)$(LIBEXECDIR)/trlde-clipboard-watch
	install -m 644 sessions/trlde.desktop $(DESTDIR)$(DATADIR)/wayland-sessions/trlde.desktop
	install -m 644 labwc/rc.xml $(DESTDIR)$(DATADIR)/trlde/labwc/rc.xml
	install -m 644 labwc/autostart $(DESTDIR)$(DATADIR)/trlde/labwc/autostart
	install -m 644 labwc/environment $(DESTDIR)$(DATADIR)/trlde/labwc/environment
	install -m 644 labwc/themerc $(DESTDIR)$(DATADIR)/themes/TRLDE/labwc/themerc
	install -m 644 waybar/config.jsonc $(DESTDIR)$(DATADIR)/trlde/waybar/config.jsonc
	install -m 644 waybar/style.css $(DESTDIR)$(DATADIR)/trlde/waybar/style.css
	install -m 644 wofi/style.css $(DESTDIR)$(DATADIR)/trlde/wofi/style.css
	install -m 644 mako/config $(DESTDIR)$(DATADIR)/trlde/mako/config
	install -m 644 mako/config $(DESTDIR)$(SYSCONFDIR)/xdg/mako/config
	install -m 644 wallpapers/trlde.svg $(DESTDIR)$(DATADIR)/backgrounds/trlde/trlde.svg
	install -m 644 wallpapers/trlde-turquoise.svg $(DESTDIR)$(DATADIR)/backgrounds/trlde/trlde-turquoise.svg
	install -m 644 wallpapers/trlde-sunset.svg $(DESTDIR)$(DATADIR)/backgrounds/trlde/trlde-sunset.svg
	install -m 644 branding/trlde-logo.svg $(DESTDIR)$(DATADIR)/pixmaps/trlde-logo.svg
	install -m 644 branding/trlde-release $(DESTDIR)$(SYSCONFDIR)/trlde-release
	install -m 644 applications/trlde-settings.desktop $(DESTDIR)$(DATADIR)/applications/trlde-settings.desktop
	install -m 644 applications/trlde-appearance.desktop $(DESTDIR)$(DATADIR)/applications/trlde-appearance.desktop
	install -m 644 applications/trlde-about.desktop $(DESTDIR)$(DATADIR)/applications/trlde-about.desktop
	install -m 644 applications/trlde-welcome.desktop $(DESTDIR)$(DATADIR)/applications/trlde-welcome.desktop
	install -m 644 applications/trlde-screenshot.desktop $(DESTDIR)$(DATADIR)/applications/trlde-screenshot.desktop
	install -m 644 applications/trlde-updates.desktop $(DESTDIR)$(DATADIR)/applications/trlde-updates.desktop
	install -m 644 applications/trlde-software.desktop $(DESTDIR)$(DATADIR)/applications/trlde-software.desktop
	install -m 644 applications/trlde-clipboard.desktop $(DESTDIR)$(DATADIR)/applications/trlde-clipboard.desktop
	install -m 644 applications/trlde-recorder.desktop $(DESTDIR)$(DATADIR)/applications/trlde-recorder.desktop
	install -m 644 applications/trlde-backup.desktop $(DESTDIR)$(DATADIR)/applications/trlde-backup.desktop
	install -m 644 applications/trlde-input.desktop $(DESTDIR)$(DATADIR)/applications/trlde-input.desktop
	install -m 644 applications/trlde-display-profiles.desktop $(DESTDIR)$(DATADIR)/applications/trlde-display-profiles.desktop
	install -m 644 gdm/01-trlde $(DESTDIR)$(SYSCONFDIR)/dconf/db/gdm.d/01-trlde
	install -m 644 plymouth/trlde.plymouth $(DESTDIR)$(DATADIR)/plymouth/themes/trlde/trlde.plymouth
	install -m 644 plymouth/trlde.script $(DESTDIR)$(DATADIR)/plymouth/themes/trlde/trlde.script
	install -m 644 portal/trlde-portals.conf $(DESTDIR)$(DATADIR)/xdg-desktop-portal/trlde-portals.conf
	install -m 644 tmpfiles/trlde-x11.conf $(DESTDIR)$(TMPFILESDIR)/trlde-x11.conf
	install -m 644 systemd/trlde-session.target $(DESTDIR)$(SYSTEMDUSERDIR)/trlde-session.target
	install -m 644 systemd/trlde-update.service $(DESTDIR)$(SYSTEMDUSERDIR)/trlde-update.service
	install -m 644 systemd/trlde-update.timer $(DESTDIR)$(SYSTEMDUSERDIR)/trlde-update.timer
	install -m 644 systemd/trlde-clipboard.service $(DESTDIR)$(SYSTEMDUSERDIR)/trlde-clipboard.service

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-session
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-launcher
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-drawer
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-lock
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-power
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-wallpaper
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-quick-settings
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-appearance
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-notifications
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-about
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-settings
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-welcome
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-run
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-screenshot
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-doctor
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-update
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-bluetooth
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-brightness
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-software
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-clipboard
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-recorder
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-backup
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-input
	rm -f $(DESTDIR)$(PREFIX)/bin/trlde-display-profiles
	rm -f $(DESTDIR)$(LIBEXECDIR)/trlde-autostart
	rm -f $(DESTDIR)$(LIBEXECDIR)/trlde-clipboard-watch
	rm -f $(DESTDIR)$(DATADIR)/wayland-sessions/trlde.desktop
	rm -rf $(DESTDIR)$(DATADIR)/trlde
	rm -rf $(DESTDIR)$(DATADIR)/backgrounds/trlde
	rm -rf $(DESTDIR)$(DATADIR)/themes/TRLDE
	rm -f $(DESTDIR)$(DATADIR)/applications/trlde-settings.desktop
	rm -f $(DESTDIR)$(DATADIR)/applications/trlde-appearance.desktop
	rm -f $(DESTDIR)$(DATADIR)/applications/trlde-about.desktop
	rm -f $(DESTDIR)$(DATADIR)/applications/trlde-welcome.desktop
	rm -f $(DESTDIR)$(DATADIR)/applications/trlde-screenshot.desktop
	rm -f $(DESTDIR)$(DATADIR)/applications/trlde-updates.desktop
	rm -f $(DESTDIR)$(DATADIR)/applications/trlde-software.desktop
	rm -f $(DESTDIR)$(DATADIR)/applications/trlde-clipboard.desktop
	rm -f $(DESTDIR)$(DATADIR)/applications/trlde-recorder.desktop
	rm -f $(DESTDIR)$(DATADIR)/applications/trlde-backup.desktop
	rm -f $(DESTDIR)$(DATADIR)/applications/trlde-input.desktop
	rm -f $(DESTDIR)$(DATADIR)/applications/trlde-display-profiles.desktop
	rm -f $(DESTDIR)$(DATADIR)/pixmaps/trlde-logo.svg
	rm -rf $(DESTDIR)$(DATADIR)/plymouth/themes/trlde
	rm -f $(DESTDIR)$(SYSCONFDIR)/xdg/mako/config
	rm -f $(DESTDIR)$(SYSCONFDIR)/dconf/db/gdm.d/01-trlde
	rm -f $(DESTDIR)$(SYSCONFDIR)/trlde-release
	rm -f $(DESTDIR)$(DATADIR)/xdg-desktop-portal/trlde-portals.conf
	rm -f $(DESTDIR)$(TMPFILESDIR)/trlde-x11.conf
	rm -f $(DESTDIR)$(SYSTEMDUSERDIR)/trlde-session.target
	rm -f $(DESTDIR)$(SYSTEMDUSERDIR)/trlde-update.service
	rm -f $(DESTDIR)$(SYSTEMDUSERDIR)/trlde-update.timer
	rm -f $(DESTDIR)$(SYSTEMDUSERDIR)/trlde-clipboard.service
