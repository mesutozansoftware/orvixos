#!/bin/sh
# live/drivers.list içinden verilen mimarinin paketlerini yazar.
# Kullanım: tools/drivers.sh arm64|amd64
arch=$1
list=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)/live/drivers.list
sed -e 's/#.*//' "$list" | while read -r first second; do
    [ -n "$first" ] || continue
    case "$first" in
        "[$arch]") printf '%s\n' "$second" ;;
        \[*\]) ;;
        *) printf '%s\n' "$first" ;;
    esac
done
