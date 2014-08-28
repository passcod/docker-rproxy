#!/usr/bin/env bash
# Reload config without breaking off connections
haproxy -f /app/haproxy.conf -p /var/run/haproxy.pid -sf $(cat /var/run/haproxy.pid)
