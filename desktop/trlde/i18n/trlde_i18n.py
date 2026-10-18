"""TRLDE uygulamaları için basit çeviri katmanı.

Oturum dili Türkçe değilse (LANG=en_US.UTF-8 gibi) GTK etiketleri, düğmeler,
pencere başlıkları ve ipuçları /usr/share/trlde/i18n/en.py sözlüğüyle
İngilizceye çevrilir. Uygulamalar `import trlde_i18n; trlde_i18n.install()`
ile etkinleştirir.
"""

import importlib.util
import os

I18N_DIR = os.path.dirname(os.path.abspath(__file__))
_TABLE = None


def language():
    for variable in ("LANGUAGE", "LC_ALL", "LC_MESSAGES", "LANG"):
        value = os.environ.get(variable)
        if value:
            return value.split(":")[0].split("_")[0].split(".")[0].lower()
    return "tr"


def table():
    global _TABLE
    if _TABLE is None:
        _TABLE = {}
        if language() != "tr":
            path = os.path.join(I18N_DIR, "en.py")
            try:
                spec = importlib.util.spec_from_file_location("trlde_i18n_en", path)
                module = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(module)
                _TABLE = dict(module.EN)
            except (OSError, AttributeError, SyntaxError):
                _TABLE = {}
    return _TABLE


def _(text):
    """Metni çevirir; bilinmeyenleri olduğu gibi bırakır."""
    if not isinstance(text, str) or not text:
        return text
    entries = table()
    if not entries:
        return text
    if text in entries:
        return entries[text]
    stripped = text.strip()
    if stripped in entries:
        return text.replace(stripped, entries[stripped])
    # "Profil uygulandı: Ofis" gibi önek / "3 pano öğesi" gibi sonek kalıpları
    for key, value in entries.items():
        if len(key) >= 4 and key.endswith((": ", " ")) and text.startswith(key):
            return value + text[len(key):]
        if len(key) >= 4 and key.startswith(" ") and text.endswith(key):
            return text[: -len(key)] + value
    return text


def install():
    if not table():
        return
    from gi.repository import Gtk

    def wrap_method(cls, name, index=0):
        original = getattr(cls, name, None)
        if original is None or getattr(original, "_trlde", False):
            return

        def method(self, *args, **kwargs):
            if len(args) > index and isinstance(args[index], str):
                args = list(args)
                args[index] = _(args[index])
            return original(self, *args, **kwargs)

        method._trlde = True
        setattr(cls, name, method)

    def wrap_init(cls):
        original = cls.__init__
        if getattr(original, "_trlde", False):
            return

        def init(self, *args, **kwargs):
            for key in ("label", "title", "subtitle", "placeholder_text", "text",
                        "secondary_text", "tooltip_text", "comments"):
                if isinstance(kwargs.get(key), str):
                    kwargs[key] = _(kwargs[key])
            if args and isinstance(args[0], str):
                args = (_(args[0]),) + tuple(args[1:])
            original(self, *args, **kwargs)

        init._trlde = True
        cls.__init__ = init

    for name in ("Label", "Button", "CheckButton", "ToggleButton", "RadioButton", "MenuItem",
                 "HeaderBar", "Window", "ApplicationWindow", "Frame", "Expander", "Entry",
                 "SearchEntry", "Dialog", "MessageDialog", "FileChooserDialog", "LinkButton",
                 "ModelButton", "AboutDialog"):
        cls = getattr(Gtk, name, None)
        if cls is not None:
            wrap_init(cls)

    for cls, methods in (
        (Gtk.Label, ("set_label", "set_text", "set_markup")),
        (Gtk.Button, ("set_label",)),
        (Gtk.Window, ("set_title",)),
        (Gtk.HeaderBar, ("set_title", "set_subtitle")),
        (Gtk.Widget, ("set_tooltip_text", "set_tooltip_markup")),
        (Gtk.Entry, ("set_placeholder_text",)),
        (Gtk.MessageDialog, ("format_secondary_text",)),
        (Gtk.AboutDialog, ("set_comments",)),
        (Gtk.ComboBoxText, ("append_text",)),
    ):
        for name in methods:
            wrap_method(cls, name)
    wrap_method(Gtk.ComboBoxText, "append", 1)
    wrap_method(Gtk.Stack, "add_titled", 2)
