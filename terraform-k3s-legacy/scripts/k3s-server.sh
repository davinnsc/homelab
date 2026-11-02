#!/bin/bash
set -euo pipefail

echo "=== Aguardando cloud-init ==="
cloud-init status --wait || true

echo "=== Instalando K3s Server ==="
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --tls-san ${SERVER_IP} --write-kubeconfig-mode 644" sh -

echo "=== Aguardando node ficar Ready ==="
until sudo kubectl get nodes 2>/dev/null | grep -q ' Ready'; do
  sleep 5
done

echo "=== K3s Server pronto! ==="
sudo kubectl get nodes
echo "=== Token ==="
sudo cat /var/lib/rancher/k3s/server/node-token
