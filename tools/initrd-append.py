#!/usr/bin/env python3
"""debian-installer initrd'sine dosya ekler.

Dosyalar ayrı bir arşiv olarak arkaya eklenmez; özgün cpio (newc) arşivinin
TRAILER kaydından önce aynı arşive yazılır (Debian'ın "cpio -A" yöntemiyle
eşdeğer). Aynı adlı dosyalar sonradan yazıldığı için öncekilerin yerini alır.

Kullanım:
    initrd-append.py GİRİŞ.gz ÇIKIŞ.gz HEDEF_YOL=KAYNAK_DOSYA ...
"""

import gzip
import os
import sys

TRAILER = b"TRAILER!!!"


def pad4(data):
    return data + b"\0" * (-len(data) % 4)


def entry(name, data, mode, ino):
    name_bytes = name.encode() + b"\0"
    fields = [ino, mode, 0, 0, 1, 1767225600, len(data), 0, 0, 0, 0, len(name_bytes), 0]
    header = b"070701" + b"".join(f"{value:08X}".encode() for value in fields)
    return pad4(header + name_bytes) + pad4(data)


def strip_trailer(archive, replaced=()):
    """TRAILER kaydını ve yerine yenisi yazılacak dosyaların eski kayıtlarını atar."""
    kept = bytearray()
    offset = 0
    while offset < len(archive):
        if archive[offset:offset + 6] != b"070701":
            raise SystemExit(f"Beklenmeyen cpio biçimi (konum {offset})")
        namesize = int(archive[offset + 94:offset + 102], 16)
        filesize = int(archive[offset + 54:offset + 62], 16)
        name = archive[offset + 110:offset + 110 + namesize - 1]
        if name == TRAILER:
            return bytes(kept)
        data_start = offset + 110 + namesize
        data_start += -data_start % 4
        end = data_start + filesize
        end += -end % 4
        if name.decode("utf-8", "replace") not in replaced:
            kept += archive[offset:end]
        offset = end
    raise SystemExit("cpio TRAILER kaydı bulunamadı")


def main():
    source, target, *items = sys.argv[1:]
    replaced = {item.split("=", 1)[0].strip("/") for item in items}
    with gzip.open(source, "rb") as handle:
        archive = strip_trailer(handle.read(), replaced)

    directories = set()
    extra = []
    ino = 900000
    for item in items:
        path, local = item.split("=", 1)
        parts = path.strip("/").split("/")
        for depth in range(1, len(parts)):
            directory = "/".join(parts[:depth])
            if directory not in directories:
                directories.add(directory)
                ino += 1
                extra.append(entry(directory, b"", 0o040755, ino))
        with open(local, "rb") as handle:
            data = handle.read()
        ino += 1
        mode = 0o100755 if os.access(local, os.X_OK) and path.endswith(".sh") else 0o100644
        extra.append(entry(path.strip("/"), data, mode, ino))
    extra.append(entry("TRAILER!!!", b"", 0, 0))

    with gzip.GzipFile(target, "wb", compresslevel=9, mtime=0) as handle:
        handle.write(archive)
        handle.write(b"".join(extra))


if __name__ == "__main__":
    main()
