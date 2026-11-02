# K3s on Proxmox with Terraform (legacy)

> **Status: retired.** This created the first version of the homelab (May 2026). The VMs were destroyed in October 2026 after the move to RKE2. Kept here because it worked and because it is the "before" of the story.

One `terraform apply` builds a 3-node K3s cluster on Proxmox:

1. Clones 3 VMs from a cloud-init Ubuntu template (`vm-server.tf`, `vm-agents.tf`).
2. SSHes into the server and installs K3s (`provisioning.tf`).
3. Reads the join token from the server and installs K3s on each agent.
4. Adds a systemd drop-in so agents wait for the API (`:6443/livez`) after a reboot. Without it, agents booting faster than the server failed to join.
5. Copies the kubeconfig to `generated/kubeconfig.yaml`, with `127.0.0.1` replaced by the server IP.

## Stack

- Provider [`bpg/proxmox`](https://registry.terraform.io/providers/bpg/proxmox/latest) `~> 0.78`
- `null` and `local` providers for provisioning
- Ubuntu 22.04 cloud-init template (VMID 9000)

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars   # fill in your values
terraform init
terraform plan
terraform apply
export KUBECONFIG=$(terraform output -raw kubeconfig_path)
kubectl get nodes
```

## Design notes

- **`cpu.type = "host"`**: exposes the real CPU flags to the VM. This mattered later: when the RKE2 nodes were cloned by hand they inherited `kvm64` and the CNI refused to start (see the main README).
- **`on_boot` + `startup.order`**: server boots first, agents 60 s later.
- **`lifecycle.ignore_changes = [network_device]`**: changes Proxmox makes to the NIC after creation are not treated as drift.
- Provisioning via SSH (`remote-exec` / `local-exec`) is simple but not idempotent. The next iteration is an Ansible playbook.
