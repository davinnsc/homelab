#!/bin/bash
set -euo pipefail

echo "=== Aguardando cloud-init ==="
cloud-init status --wait || true

echo "=== Instalando K3s Agent ==="
curl -sfL https://get.k3s.io | K3S_URL="https://${SERVER_IP}:6443" K3S_TOKEN="${K3S_TOKEN}" sh -

echo "=== Aguardando registro no cluster ==="
sleep 15

echo "=== K3s Agent instalado! ==="
