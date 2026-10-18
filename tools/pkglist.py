#!/usr/bin/env python3
"""OrvixOS paketlerinin Debian bağımlılıklarını listeler ve denetler.

Kullanım:
    pkglist.py include [--packages Packages.xz]
        Kurulumun pkgsel/include adımında Debian'dan kurulacak paketleri
        (OrvixOS paketleri ve gdm3 hariç) tek satırda yazar. --packages
        verilirse her adın Debian deposunda bulunduğu da denetlenir.
"""

import argparse
import lzma
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OWN = {"vpx", "trlde", "vira-browser", "orvixos-base", "orvixos-desktop"}
# Giriş ekranı kurulumun son adımında, önerileri olmadan kurulur
# (iso/late-install.sh).
LATE = {"sddm"}
EXTRA = []


def fields(control):
    text = control.read_text(encoding="utf-8")
    result = {}
    for match in re.finditer(r"^(Depends|Recommends): (.+)$", text, re.M):
        result[match.group(1)] = match.group(2)
    return result


def names(relation):
    for item in relation.split(","):
        first = item.split("|")[0].strip()
        if first:
            yield re.split(r"[\s(]", first)[0]


def collect():
    ordered = []
    for package in ("trlde", "vira-browser", "orvixos-base", "orvixos-desktop"):
        control = ROOT / "packages" / package / "DEBIAN" / "control"
        for relation in fields(control).values():
            for name in names(relation):
                if name not in OWN and name not in LATE and name not in ordered:
                    ordered.append(name)
    return ordered


def available(index):
    data = lzma.open(index).read().decode("utf-8", "replace")
    known = set(re.findall(r"^Package: (\S+)$", data, re.M))
    for provides in re.findall(r"^Provides: (.+)$", data, re.M):
        known.update(re.split(r"[\s(]", p.strip())[0] for p in provides.split(","))
    return known


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["include"])
    parser.add_argument("--packages", action="append", default=[])
    args = parser.parse_args()

    packages = collect()
    for index in args.packages:
        known = available(index)
        missing = [p for p in packages + EXTRA + sorted(LATE) if p not in known]
        if missing:
            print(f"{index}: Debian deposunda bulunamadı: {' '.join(missing)}", file=sys.stderr)
            sys.exit(1)
    print(" ".join(packages))


if __name__ == "__main__":
    main()
