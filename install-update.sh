tee /opt/docker/docker-portainer-service/install-update.sh > /dev/null << 'EOF'
#!/bin/bash
set -e

PORTAINER_DATA="/opt/docker/container-data/portainer"

echo "=== 1. Tjekker og opdaterer Docker ==="

if ! command -v curl &> /dev/null; then
    apt-get update && apt-get install -y curl ca-certificates
fi

if ! command -v docker &> /dev/null; then
    echo "Docker ikke fundet. Installerer Docker for første gang..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sh /tmp/get-docker.sh
    rm -f /tmp/get-docker.sh
    systemctl enable docker
    systemctl start docker
else
    echo "Docker fundet. Tjekker for pakkeopdateringer via apt..."
    apt-get update -qq
    apt-get --only-upgrade install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin 2>/dev/null || true
fi

echo "=== 2. Forbereder Portainer data-mappe ==="
mkdir -p "${PORTAINER_DATA}"

echo "=== 3. Henter og opdaterer Portainer CE ==="
echo "Henter nyeste image..."
docker pull portainer/portainer-ce:latest

echo "Stopper og fjerner eksisterende Portainer container (hvis den findes)..."
docker stop portainer 2>/dev/null || true
docker rm portainer 2>/dev/null || true

echo "Starter Portainer..."
docker run -d \
  -p 9443:9443 \
  -p 8000:8000 \
  --name portainer \
  --restart always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "${PORTAINER_DATA}:/data" \
  -v /etc/localtime:/etc/localtime:ro \
  portainer/portainer-ce:latest

echo "=== 4. Oprydning ==="
docker image prune -f

SERVER_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' || echo "192.168.40.10")

echo "=== Færdig! ==="
echo "Portainer kører nu på: https://${SERVER_IP}:9443"
EOF

chmod +x /opt/docker/docker-portainer-service/install-update.sh
