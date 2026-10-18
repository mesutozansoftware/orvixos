#!/usr/bin/env python3
"""Sitedeki canlı ISO indirme kartlarını outputs/ içindeki ISO'lara göre günceller.

Her mimari için SHA-256 değeri ve boyut (TR ve EN) yazılır.
Kullanım: tools/update-site.py [arm64] [amd64]
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SITE = ROOT / "site" / "index.html"
VERSION = dict(re.findall(r"^(\w+)=(\S+)", (ROOT / "orvixos.conf").read_text(), re.M))["ORVIXOS_VERSION"]
KEYS = {"arm64": "dl.arm64.size", "amd64": "dl.x64.size"}


def main():
    arches = sys.argv[1:] or ["arm64", "amd64"]
    html = SITE.read_text(encoding="utf-8")
    for arch in arches:
        iso = ROOT / "outputs" / f"OrvixOS-{VERSION}-live-{arch}.iso"
        checksum_file = iso.with_name(iso.name + ".sha256")
        if not iso.exists() or not checksum_file.exists():
            print(f"{arch}: ISO ya da .sha256 yok, atlandı")
            continue
        checksum = checksum_file.read_text().split()[0]
        size = iso.stat().st_size / 1024 ** 3
        size_tr = f"{size:.2f}".replace(".", ",") + " GB"
        size_en = f"{size:.2f} GB"

        # İndirme bağlantısından sonraki ilk SHA-256 değeri
        link = f"OrvixOS-{VERSION}-live-{arch}.iso"
        start = html.find(link)
        if start < 0:
            print(f"{arch}: sitede indirme bağlantısı bulunamadı")
            continue
        match = re.compile(r'(<span class="mono">)([0-9a-f]{64})(</span>)').search(html, start)
        html = html[: match.start(2)] + checksum + html[match.end(2):]

        key = KEYS[arch]
        html = re.sub(
            rf'(<span data-i18n="{re.escape(key)}">)[^<]*(</span>)',
            rf"\g<1>Canlı ISO • {size_tr}\g<2>",
            html,
        )
        html = re.sub(rf'("{re.escape(key)}": ")[^"]*(")', rf"\g<1>Live ISO • {size_en}\g<2>", html)
        print(f"{arch}: {size_tr}, {checksum[:12]}…")
    SITE.write_text(html, encoding="utf-8")


if __name__ == "__main__":
    main()
