#!/bin/sh
set -u

NET_IF=""
tries=0
while [ "$tries" -lt 20 ]; do
    if ifconfig vtnet1 >/dev/null 2>&1; then
        NET_IF=vtnet1
        break
    fi
    if ifconfig vtnet0 >/dev/null 2>&1; then
        NET_IF=vtnet0
        break
    fi
    tries=`expr "$tries" + 1`
    sleep 1
done

if [ -z "$NET_IF" ]; then
    echo "udp-telemetry-server: no vtnet interface found"
else
    ifconfig "$NET_IF" 192.168.10.2/24 up || true
    echo "udp-telemetry-server: configured $NET_IF 192.168.10.2/24"
fi

exec udp-telemetry-server 5002
