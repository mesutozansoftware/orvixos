#!/usr/bin/env python3
"""Depodaki paketler için kısa indirme adresleri ve liste sayfası üretir.

  /repo                      → /paketler (paket listesi sayfası)
  /repo/<paket>              → en son .deb (birden çok mimari varsa amd64)
  /repo/<paket>/<mimari>     → o mimarinin .deb'i
  /repo/<dosya>              → GitHub'daki dosya (APT bunu kullanır)

Girdi: build/repo/*.deb ve repo/packages.list. Çıktı: site/vercel.json ve
site/paketler.html. tools/repo-build.sh çağırır.
"""

import html
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REPO = ROOT / "build" / "repo"
BASE = "https://github.com/mesutozansoftware/orvixos/releases/download/packages"

DESCRIPTIONS = {
    "vpx": ("OrvixOS paket yöneticisi (APT tabanlı)", "OrvixOS package manager (APT based)"),
    "orvixos-base": ("OrvixOS temel sistem dosyaları ve depo anahtarı", "OrvixOS base files and repository key"),
    "orvixos-desktop": ("OrvixOS masaüstü meta paketi", "OrvixOS desktop meta package"),
    "trlde": ("TRLDE Wayland masaüstü ortamı", "TRLDE Wayland desktop environment"),
    "vira-browser": ("Hızlı, gizlilik odaklı tarayıcı", "Fast, privacy-focused browser"),
    "subpulse": ("Alan adı keşfi ve HTTP yoklama aracı", "Subdomain discovery and HTTP probing"),
    "chestzip": ("Arşiv yöneticisi", "Archive manager"),
    "pybench": ("Bilgisayar performans testi", "Computer benchmark"),
    "nanolimiter": ("Az bellekli HTTP ters vekil ve hız sınırlayıcı", "Low-memory HTTP reverse proxy and rate limiter"),
    "codium": ("VSCodium kod düzenleyici", "VSCodium code editor"),
    "heroic": ("Epic ve GOG oyun başlatıcısı", "Epic and GOG game launcher"),
}
ARCH_NAMES = {"amd64": "x64", "arm64": "ARM64", "all": "x64 + ARM64"}


def version_key(version):
    return [int(part) if part.isdigit() else part for part in re.split(r"[.\-+~]", version)]


def packages():
    found = {}
    for deb in sorted(REPO.glob("*.deb")):
        match = re.match(r"^(.+?)_(.+)_(amd64|arm64|all)\.deb$", deb.name)
        if not match:
            continue
        name, version, arch = match.groups()
        current = found.setdefault(name, {}).get(arch)
        if current is None or version_key(version) > version_key(current[0]):
            found[name][arch] = (version, deb.name)
    return found


def main():
    found = packages()
    redirects = [{"source": "/repo", "destination": "/paketler", "permanent": False},
                 {"source": "/repo/", "destination": "/paketler", "permanent": False}]
    for name, arches in sorted(found.items()):
        default = arches.get("all") or arches.get("amd64") or next(iter(arches.values()))
        redirects.append({"source": f"/repo/{name}", "destination": f"{BASE}/{default[1]}", "permanent": False})
        for arch, (_version, filename) in sorted(arches.items()):
            if arch != "all":
                redirects.append({"source": f"/repo/{name}/{arch}", "destination": f"{BASE}/{filename}",
                                  "permanent": False})
    redirects.append({"source": "/repo/:path*", "destination": f"{BASE}/:path*", "permanent": False})
    (ROOT / "site" / "vercel.json").write_text(
        json.dumps({"cleanUrls": True, "redirects": redirects}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8")

    rows = []
    for name, arches in sorted(found.items()):
        tr, en = DESCRIPTIONS.get(name, ("", ""))
        version = max((v for v, _f in arches.values()), key=version_key)
        links = []
        for arch, (_v, _f) in sorted(arches.items()):
            href = f"/repo/{name}" if arch in ("all",) or len(arches) == 1 else f"/repo/{name}/{arch}"
            links.append(f'<a class="btn" href="{href}">{ARCH_NAMES[arch]}</a>')
        rows.append(
            f'<div class="pkg"><div><h3>{html.escape(name)} <span class="ver">{html.escape(version)}</span></h3>'
            f'<p data-tr="{html.escape(tr)}" data-en="{html.escape(en)}">{html.escape(tr)}</p>'
            f'<code>vpx install {html.escape(name)}</code></div><div class="links">{"".join(links)}</div></div>')
    page = PAGE.replace("@ROWS@", "\n".join(rows))
    (ROOT / "site" / "paketler.html").write_text(page, encoding="utf-8")
    print(f"{len(found)} paket, {len(redirects)} yönlendirme")


PAGE = """<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>OrvixOS Paket Deposu</title>
  <meta name="description" content="OrvixOS paket deposundaki programlar: vpx install ile kur ya da .deb olarak indir.">
  <link rel="icon" type="image/svg+xml" href="logo.svg">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&family=JetBrains+Mono&display=swap" rel="stylesheet">
  <style>
    :root { --bg: #0b1220; --card: #111a2c; --border: #1f2b44; --text: #e8edf7; --muted: #9ba1b6; --teal: #2ee6d6; }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { background: var(--bg); color: var(--text); font-family: Inter, system-ui, sans-serif; line-height: 1.6; }
    .wrap { max-width: 920px; margin: 0 auto; padding: 48px 16px 72px; }
    a { color: var(--teal); text-decoration: none; }
    header { display: flex; justify-content: space-between; align-items: center; gap: 12px; margin-bottom: 36px; }
    h1 { font-size: 34px; font-weight: 800; margin-bottom: 8px; }
    .lead { color: var(--muted); margin-bottom: 28px; }
    .pkg { display: flex; justify-content: space-between; align-items: center; gap: 16px; background: var(--card);
           border: 1px solid var(--border); border-radius: 14px; padding: 18px 20px; margin-bottom: 12px; }
    .pkg h3 { font-size: 18px; }
    .pkg .ver { color: var(--muted); font-weight: 400; font-size: 14px; margin-left: 6px; }
    .pkg p { color: var(--muted); font-size: 14.5px; margin: 2px 0 8px; }
    code { font-family: "JetBrains Mono", monospace; font-size: 13px; background: #070c16; border: 1px solid var(--border);
           border-radius: 6px; padding: 2px 8px; color: #cfd6e6; }
    .links { display: flex; gap: 8px; flex-wrap: wrap; justify-content: flex-end; }
    .btn { display: inline-block; padding: 8px 14px; border-radius: 9px; background: var(--teal); color: #071019;
           font-weight: 600; font-size: 14px; white-space: nowrap; }
    .lang { background: transparent; border: 1px solid var(--border); color: var(--text); border-radius: 8px;
            padding: 6px 12px; cursor: pointer; font: inherit; }
    .note { color: var(--muted); font-size: 14px; margin-top: 24px; }
    @media (max-width: 640px) { .pkg { flex-direction: column; align-items: flex-start; } .links { justify-content: flex-start; } }
  </style>
</head>
<body>
  <div class="wrap">
    <header><a href="/">← OrvixOS</a><button class="lang" id="lang">EN</button></header>
    <h1 data-tr="OrvixOS paket deposu" data-en="OrvixOS package repository">OrvixOS paket deposu</h1>
    <p class="lead" data-tr="OrvixOS'ta kurmak için komutu yaz; başka bir Debian tabanlı sistemde .deb dosyasını indirip vpx install ./dosya.deb ya da sudo apt install ./dosya.deb ile kur. Depo imzalıdır."
       data-en="On OrvixOS, run the command; on another Debian-based system, download the .deb and install it with sudo apt install ./file.deb. The repository is signed.">OrvixOS'ta kurmak için komutu yaz; başka bir Debian tabanlı sistemde .deb dosyasını indirip vpx install ./dosya.deb ya da sudo apt install ./dosya.deb ile kur. Depo imzalıdır.</p>
@ROWS@
    <p class="note" data-tr="Kısa adresler: orvixos.vercel.app/repo/PAKET (ARM için /repo/PAKET/arm64). Tüm dosyalar: GitHub'daki packages sürümü."
       data-en="Short links: orvixos.vercel.app/repo/PACKAGE (ARM: /repo/PACKAGE/arm64). All files: the packages release on GitHub.">Kısa adresler: orvixos.vercel.app/repo/PAKET (ARM için /repo/PAKET/arm64). Tüm dosyalar: GitHub'daki packages sürümü.</p>
    <p class="note"><a href="https://github.com/mesutozansoftware/orvixos/releases/tag/packages">github.com/mesutozansoftware/orvixos/releases/tag/packages</a></p>
  </div>
  <script>
    (function () {
      var lang = "tr";
      try { lang = localStorage.getItem("orvixos-lang") || (navigator.language || "tr").slice(0, 2); } catch (e) {}
      function apply() {
        document.documentElement.lang = lang === "tr" ? "tr" : "en";
        document.querySelectorAll("[data-tr]").forEach(function (el) {
          el.textContent = el.getAttribute(lang === "tr" ? "data-tr" : "data-en");
        });
        document.getElementById("lang").textContent = lang === "tr" ? "EN" : "TR";
      }
      document.getElementById("lang").addEventListener("click", function () {
        lang = lang === "tr" ? "en" : "tr";
        try { localStorage.setItem("orvixos-lang", lang); } catch (e) {}
        apply();
      });
      if (lang !== "tr") { lang = "en"; }
      apply();
    })();
  </script>
</body>
</html>
"""


if __name__ == "__main__":
    main()
