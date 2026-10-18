#!/bin/sh
# Test sanal makinesinde root olarak komut çalıştırır (yalnızca geliştirme).
# Parola, test ISO'sunun preseed dosyasındaki test kullanıcısına aittir.
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
exec ssh -q -i "$root/build/test/id_ed25519" -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null -o ServerAliveInterval=30 -p 2222 orvix@127.0.0.1 \
    "echo orvixtest | sudo -S -p '' sh -c '$*'"
