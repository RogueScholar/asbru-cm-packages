#!/usr/bin/env bash

# OOMScoreAdjust cannot be used in Docker containers.
# By setting it to null we should be able to disable it.

for service in systemd-udevd dbus; do
mkdir -p /etc/systemd/system/$service.service.d
cat > /etc/systemd/system/$service.service.d/disable-oomscoreadjust.conf <<DISABLEOOMSCORE
[Service]
OOMScoreAdjust=0
DISABLEOOMSCORE

done

mkdir -p /etc/systemd/user/dbus.service.d
cat > /etc/systemd/user/dbus.service.d/disable-oomscoreadjust.conf <<DISABLEOOMSCORE
[Service]
OOMScoreAdjust=0
DISABLEOOMSCORE

systemctl daemon-reload && systemctl --user daemon-reload
systemctl restart dbus && systemctl --user restart dbus
