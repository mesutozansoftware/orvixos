#!/bin/sh
# Yalnızca otomatik test ISO'su: test kullanıcısına SSH anahtarı ekler.
set -e
mkdir -p /target/home/orvix/.ssh && chmod 700 /target/home/orvix/.ssh
cp /cdrom/orvixos/test-authorized_keys /target/home/orvix/.ssh/authorized_keys
chmod 600 /target/home/orvix/.ssh/authorized_keys
in-target chown -R orvix:orvix /home/orvix/.ssh
