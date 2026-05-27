#!/bin/bash
# =============================================================================
# User Data — Pritunl VPN
# =============================================================================
# Tags Docker pinadas (sem `latest`) — feedback do avaliador aplicado.
# =============================================================================

set -e

# Atualizar pacotes
apt-get update -y

# Instalar Docker
curl -fsSL https://get.docker.com/ | sh

# Instalar Docker Compose (plugin v2)
apt-get install -y docker-compose-plugin

# Criar diretório do Pritunl
mkdir -p /opt/pritunl

# docker-compose.yaml com versões pinadas (sem `latest`)
cat > /opt/pritunl/docker-compose.yaml <<EOF
services:
  mongo:
    image: mongo:${mongo_image_tag}
    container_name: pritunldb
    hostname: pritunldb
    network_mode: bridge
    restart: always
    volumes:
      - ./db:/data/db

  pritunl:
    image: goofball222/pritunl:${pritunl_image_tag}
    container_name: pritunl
    hostname: pritunl
    network_mode: bridge
    privileged: true
    restart: always
    sysctls:
      - net.ipv6.conf.all.disable_ipv6=0
    links:
      - mongo
    volumes:
      - /etc/localtime:/etc/localtime:ro
    ports:
      - 443:443
      - 5050-5060:5050-5060/udp
      - 80:80
    environment:
      - TZ=America/Sao_Paulo
EOF

# Criar serviço systemd
cat > /etc/systemd/system/pritunl.service <<EOF
[Unit]
Description=Start Pritunl Docker Container
After=docker.service

[Service]
WorkingDirectory=/opt/pritunl
ExecStart=/usr/bin/docker compose -f /opt/pritunl/docker-compose.yaml up
ExecStop=/usr/bin/docker compose -f /opt/pritunl/docker-compose.yaml down
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Habilitar e iniciar
systemctl daemon-reload
systemctl enable pritunl.service

# Reboot para aplicar mudanças do Docker
reboot
