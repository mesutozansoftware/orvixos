#!/usr/bin/env python3
"""QEMU seri konsoluna bağlanıp debian-installer'ı izler (test aracı).

- Tüm çıktıyı günlüğe yazar.
- Tarayıcı seçim sorusu ekrana gelince varsayılanı (Vira Browser) Enter ile seçer.
- Aynı ekran uzun süre değişmezse (takılma) bunu günlüğe not eder.

Kullanım: serial-driver.py SOKET GÜNLÜK [ZAMAN_AŞIMI_SN]
"""

import re
import socket
import sys
import time

sock_path, log_path = sys.argv[1], sys.argv[2]
timeout = int(sys.argv[3]) if len(sys.argv) > 3 else 5400

ANSWERS = [
    # (ekranda aranan metin, gönderilecek tuş, açıklama)
    (b"Web browser:", b"\r", "tarayıcı sorusu: varsayılan seçildi"),
    (b"Web taray", b"\r", "tarayıcı sorusu: varsayılan seçildi"),
]

client = None
for _ in range(60):
    try:
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        client.connect(sock_path)
        break
    except OSError:
        time.sleep(1)
else:
    sys.exit("seri sokete bağlanılamadı")

client.settimeout(5)
answered = set()
recent = b""
start = time.time()
last_change = time.time()
last_title = b""
with open(log_path, "ab") as log, open(log_path + ".events", "a") as events:
    def event(text):
        events.write(f"[{int(time.time() - start):5d}s] {text}\n")
        events.flush()

    event("bağlandı")
    while time.time() - start < timeout:
        try:
            data = client.recv(65536)
        except socket.timeout:
            data = None
        if data == b"":
            event("QEMU kapandı")
            break
        if data:
            log.write(data)
            log.flush()
            recent = (recent + data)[-20000:]
            for index, (needle, keys, label) in enumerate(ANSWERS):
                if index not in answered and needle in recent:
                    time.sleep(2)
                    client.sendall(keys)
                    answered.update(i for i, a in enumerate(ANSWERS) if a[2] == label)
                    event(label)
            # Ekran başlığı ("[!!] ..." ya da ilerleme penceresi) değişti mi?
            titles = re.findall(rb"(?:\[!+\] )?([A-Z][A-Za-z ,'-]{6,60}?)\s{2,}", data)
            if titles and titles[-1] != last_title:
                last_title = titles[-1]
                last_change = time.time()
                event("ekran: " + last_title.decode("ascii", "replace"))
        # Elle tuş göndermek için: printf '\x014' > /tmp/oxs.cmd (screen: Ctrl-a 4 = günlük)
        try:
            with open("/tmp/oxs.cmd", "rb") as command:
                keys = command.read()
            import os
            os.remove("/tmp/oxs.cmd")
            client.sendall(keys)
            event(f"tuş gönderildi: {keys!r}")
        except FileNotFoundError:
            pass
        if time.time() - last_change > 900:
            event("UYARI: 15 dakikadır ekran değişmedi: " + last_title.decode("ascii", "replace"))
            last_change = time.time()
    else:
        event("zaman aşımı")
