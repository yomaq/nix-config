





### To convert + allow direct access into the tailscale container + connect to pihole
# version: "3"
# services:
#   tailnord-exit:
#     container_name: tailnord
#     image: tailscale/tailscale
#     network_mode: service:nord-exit
#     environment:
#       - TS_AUTHKEY=
#       - TS_HOSTNAME=tailnord
#       - TS_STATE_DIR='/var/lib/tailscale'
#       - TS_EXTRA_ARGS=--advertise-exit-node
#     volumes:
#       - ./data/lib:/var/lib # State data will be stored in this directory
#       - /dev/net/tun:/dev/net/tun  # Required for tailscale to work
#     cap_add:
#       - NET_ADMIN
#       - NET_RAW
#     restart: unless-stopped
#   nord-exit:
#     image: ghcr.io/bubuntux/nordlynx
#     container_name: nord-exit
#     cap_add:
#       - NET_ADMIN
#     environment:
#      - PRIVATE_KEY=
#     restart: unless-stopped