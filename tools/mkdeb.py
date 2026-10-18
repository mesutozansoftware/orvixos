#!/usr/bin/env python3
"""Bir hazırlık dizininden Debian ikili paketi (.deb) üretir.

macOS üzerinde dpkg-deb gerektirmeden çalışır. Dosya sahipliği her zaman
root:root yazılır; kip bitleri hazırlık dizininden alınır. Ayrıca belirli
yollar için kip bitleri --mode YOL=KİP ile zorlanabilir (ör. setuid).

Kullanım:
    mkdeb.py --root STAGE --control CONTROL_DIR --output paket.deb \
             [--mode usr/lib/x/chrome-sandbox=4755]
"""

import argparse
import hashlib
import io
import os
import stat
import sys
import tarfile
import time

SOURCE_DATE_EPOCH = int(os.environ.get("SOURCE_DATE_EPOCH", "1767225600"))
CONTROL_SCRIPTS = {"preinst", "postinst", "prerm", "postrm", "config"}


def tar_filter(modes):
    def apply(info):
        info.uid = info.gid = 0
        info.uname = info.gname = "root"
        info.mtime = SOURCE_DATE_EPOCH
        relative = info.name[2:] if info.name.startswith("./") else info.name
        if relative in modes:
            info.mode = modes[relative]
        elif info.isdir():
            info.mode = 0o755
        elif info.isfile():
            info.mode = 0o755 if info.mode & 0o111 else 0o644
        return info

    return apply


def walk_sorted(root):
    entries = []
    for directory, dirnames, filenames in os.walk(root):
        dirnames.sort()
        for name in sorted(dirnames) + sorted(filenames):
            if name == ".DS_Store" or name.startswith("._"):
                continue
            entries.append(os.path.join(directory, name))
    return sorted(entries, key=lambda p: os.path.relpath(p, root))


def build_data(root, modes):
    buffer = io.BytesIO()
    md5sums = []
    installed_size = 0
    with tarfile.open(fileobj=buffer, mode="w:xz", format=tarfile.GNU_FORMAT) as tar:
        tar.add(root, arcname=".", recursive=False, filter=tar_filter(modes))
        for path in walk_sorted(root):
            relative = os.path.relpath(path, root)
            tar.add(path, arcname="./" + relative, recursive=False, filter=tar_filter(modes))
            st = os.lstat(path)
            if stat.S_ISREG(st.st_mode):
                with open(path, "rb") as handle:
                    md5sums.append(f"{hashlib.md5(handle.read()).hexdigest()}  {relative}\n")
                installed_size += st.st_size
            else:
                installed_size += 1024
    return buffer.getvalue(), "".join(md5sums), max(1, (installed_size + 1023) // 1024)


def build_control(control_dir, md5sums, installed_size):
    with open(os.path.join(control_dir, "control"), encoding="utf-8") as handle:
        control = handle.read().rstrip("\n").split("\n")
    control = [line for line in control if not line.startswith("Installed-Size:")]
    for index, line in enumerate(control):
        if line.startswith("Description:"):
            control.insert(index, f"Installed-Size: {installed_size}")
            break
    control_text = "\n".join(control) + "\n"

    buffer = io.BytesIO()
    with tarfile.open(fileobj=buffer, mode="w:xz", format=tarfile.GNU_FORMAT) as tar:
        def add_bytes(name, data, mode=0o644):
            info = tarfile.TarInfo("./" + name)
            info.size = len(data)
            info.mode = mode
            info.mtime = SOURCE_DATE_EPOCH
            info.uname = info.gname = "root"
            tar.addfile(info, io.BytesIO(data))

        directory = tarfile.TarInfo(".")
        directory.type = tarfile.DIRTYPE
        directory.mode = 0o755
        directory.mtime = SOURCE_DATE_EPOCH
        directory.uname = directory.gname = "root"
        tar.addfile(directory)
        add_bytes("control", control_text.encode("utf-8"))
        add_bytes("md5sums", md5sums.encode("utf-8"))
        for name in sorted(os.listdir(control_dir)):
            if name in ("control", "md5sums") or name.startswith("."):
                continue
            with open(os.path.join(control_dir, name), "rb") as handle:
                data = handle.read()
            add_bytes(name, data, 0o755 if name in CONTROL_SCRIPTS else 0o644)
    return buffer.getvalue()


def ar_member(name, data):
    header = (
        f"{name:<16}{SOURCE_DATE_EPOCH:<12}{0:<6}{0:<6}{100644:<8}{len(data):<10}`\n"
    ).encode("ascii")
    assert len(header) == 60
    return header + data + (b"\n" if len(data) % 2 else b"")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--control", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--mode", action="append", default=[])
    args = parser.parse_args()

    modes = {}
    for item in args.mode:
        path, mode = item.split("=", 1)
        modes[path.lstrip("/")] = int(mode, 8)

    data, md5sums, installed_size = build_data(args.root, modes)
    control = build_control(args.control, md5sums, installed_size)
    with open(args.output, "wb") as handle:
        handle.write(b"!<arch>\n")
        handle.write(ar_member("debian-binary", b"2.0\n"))
        handle.write(ar_member("control.tar.xz", control))
        handle.write(ar_member("data.tar.xz", data))
    print(f"{os.path.basename(args.output)}: {installed_size} KiB", file=sys.stderr)


if __name__ == "__main__":
    main()
