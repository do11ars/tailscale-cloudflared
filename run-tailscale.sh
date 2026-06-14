#!/usr/bin/env bash

/render/tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &
PID=$!

until /render/tailscale up --authkey="${TAILSCALE_AUTHKEY}" --hostname="${RENDER_SERVICE_NAME}"; do
  sleep 0.1
done

tailscale_ip=$(/render/tailscale ip)
echo "Tailscale is up at IP ${tailscale_ip}"

socat TCP4-LISTEN:80,fork,reuseaddr SOCKS5:127.0.0.1:1055:100.66.66.66:80 &
SOCAT_PID=$!
socat TCP4-LISTEN:5432,fork,reuseaddr SOCKS5:127.0.0.1:1055:100.66.66.66:5432 &
SOCAT2_PID=$!
/usr/local/bin/cloudflared tunnel --no-autoupdate run --token "${TUNNEL_TOKEN}" &
TUNNEL_PID=$!

wait ${PID} ${TUNNEL_PID} ${SOCAT_PID} ${SOCAT2_PID}
