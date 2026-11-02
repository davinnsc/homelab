# Installing RKE2 (1 server + 2 agents)

Installed by hand on purpose, as interview practice. These are the exact steps.

| Node | Role | IP |
|---|---|---|
| rke2-server-1 | control-plane + etcd | 192.168.86.201 |
| rke2-agent-1 | worker | 192.168.86.211 |
| rke2-agent-2 | worker | 192.168.86.212 |

## Why RKE2 and not K3s

K3s runs the whole control plane inside a single binary: light, great for the edge. RKE2 runs `kube-apiserver`, `kube-controller-manager`, `kube-scheduler` and `etcd` as separate **static pods**, the way a production Kubernetes does, with CIS-hardened defaults and SELinux support. Heavier, and the usual pick on-premise when security matters.

## 1. Server

```bash
sudo mkdir -p /etc/rancher/rke2
sudo cp server-config.yaml /etc/rancher/rke2/config.yaml   # see server-config.yaml

curl -sfL https://get.rke2.io | sudo sh -
sudo systemctl enable --now rke2-server.service
sudo journalctl -u rke2-server -f    # first start takes 2-5 min (pulls control plane images)

echo 'export PATH=$PATH:/var/lib/rancher/rke2/bin' >> ~/.bashrc
echo 'export KUBECONFIG=/etc/rancher/rke2/rke2.yaml' >> ~/.bashrc
source ~/.bashrc
kubectl get nodes -o wide
```

## 2. Join token

```bash
sudo cat /var/lib/rancher/rke2/server/node-token
```

Without a token, any machine that reaches the cluster port could register as a node, and a node can run workloads and read the secrets of the pods it hosts.

## 3. Agents

On each agent, with its own `node-ip`:

```bash
sudo mkdir -p /etc/rancher/rke2
sudo cp agent-config.yaml /etc/rancher/rke2/config.yaml    # edit token and node-ip

curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_TYPE="agent" sh -
sudo systemctl enable --now rke2-agent.service
```

Three things that break if you get them wrong:

- **Port 9345, not 6443.** 6443 is the Kubernetes API; 9345 is RKE2 node registration.
- **`INSTALL_RKE2_TYPE="agent"` is mandatory.** Without it you install a second server.
- **`node-ip` must be unique.** Copy-pasting the file without changing it makes two nodes announce the same IP (it happened, see the main README).

## 4. Validate

```bash
kubectl get nodes -o wide   # 3 x Ready
kubectl get pods -A         # control plane components visible as separate pods in kube-system
```

## 5. Kubeconfig on your machine

```bash
ssh rke2-server "sudo cat /etc/rancher/rke2/rke2.yaml" \
  | sed 's/127.0.0.1/192.168.86.201/' > ~/.kube/config-rke2
export KUBECONFIG=~/.kube/config-rke2
```

The `sed` works only because that IP is in `tls-san`; otherwise the API certificate is rejected.
