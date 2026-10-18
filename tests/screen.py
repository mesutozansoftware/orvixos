#!/usr/bin/env python3
"""Seri konsol günlüğündeki son debian-installer ekranını düz metin olarak yazar.

Kullanım: tests/screen.py install-arm64.log
"""

import re
import sys

data = open(sys.argv[1], "rb").read()[-60000:].decode("utf-8", "replace")
# Basit bir 24x80 terminal öykünmesi: imleç konumlandırma ve yazı.
rows = [[" "] * 80 for _ in range(25)]
row = col = 0
for token in re.findall(r"\x1b\[[0-9;?]*[A-Za-z]|\x1b[()][0-9AB]|\x1b.|[^\x1b]", data, re.S):
    if token.startswith("\x1b["):
        args = [int(a) if a.isdigit() else 0 for a in token[2:-1].lstrip("?").split(";")]
        cmd = token[-1]
        if cmd in "Hf":
            row = max(1, args[0] if args and args[0] else 1) - 1
            col = max(1, args[1] if len(args) > 1 and args[1] else 1) - 1
        elif cmd == "J" and (not args or args[0] in (0, 2)):
            for r in range(row if args and args[0] == 0 else 0, 25):
                rows[r] = [" "] * 80
        elif cmd == "A":
            row = max(0, row - (args[0] or 1))
        elif cmd == "B":
            row = min(24, row + (args[0] or 1))
        elif cmd == "C":
            col = min(79, col + (args[0] or 1))
        elif cmd == "D":
            col = max(0, col - (args[0] or 1))
        continue
    if token.startswith("\x1b"):
        continue
    if token == "\n":
        row = min(24, row + 1)
        continue
    if token == "\r":
        col = 0
        continue
    if token.isprintable() and row < 25 and col < 80:
        rows[row][col] = token
        col += 1
for line in rows:
    text = "".join(line).rstrip()
    text = re.sub(r"[lqkxmjtu]{6,}", lambda m: "-" * len(m.group()), text)
    if text.strip():
        print(text)
