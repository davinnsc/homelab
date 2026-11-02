locals {
  server_ip_clean = split("/", var.server_ip)[0]
  agent_ips_clean = [for ip in var.agent_ips : split("/", ip)[0]]
  ssh_private_key = pathexpand(var.ssh_private_key_path)
  k3s_install_url = "https://get.k3s.io"
  k3s_version_arg = var.k3s_version != "" ? "INSTALL_K3S_VERSION=${var.k3s_version}" : ""
}

# =============================================================================
# Instalar K3s Server
# =============================================================================
resource "null_resource" "k3s_server_install" {
  depends_on = [proxmox_virtual_environment_vm.k3s_server]

  connection {
    type        = "ssh"
    host        = local.server_ip_clean
    user        = var.ssh_user
    private_key = file(local.ssh_private_key)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Aguardando cloud-init finalizar...'",
      "cloud-init status --wait || true",
      "echo 'Instalando k3s server...'",
      "curl -sfL ${local.k3s_install_url} | ${local.k3s_version_arg} INSTALL_K3S_EXEC='server --tls-san ${local.server_ip_clean} --write-kubeconfig-mode 644' sh -",
      "echo 'Aguardando k3s ficar pronto...'",
      "until sudo kubectl get nodes 2>/dev/null | grep -q ' Ready'; do sleep 5; done",
      "echo 'K3s server instalado com sucesso!'",
    ]
  }
}

# =============================================================================
# Coletar Token e Instalar Agents
# =============================================================================
resource "null_resource" "k3s_agent_install" {
  count      = var.agent_count
  depends_on = [null_resource.k3s_server_install, proxmox_virtual_environment_vm.k3s_agent]

  provisioner "local-exec" {
    command = <<-EOT
      TOKEN=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${local.ssh_private_key} ${var.ssh_user}@${local.server_ip_clean} 'sudo cat /var/lib/rancher/k3s/server/node-token' 2>/dev/null | tr -d '[:space:]')
      ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${local.ssh_private_key} ${var.ssh_user}@${local.agent_ips_clean[count.index]} "cloud-init status --wait || true && curl -sfL https://get.k3s.io | ${local.k3s_version_arg} K3S_URL=https://${local.server_ip_clean}:6443 K3S_TOKEN=$TOKEN sh - && sleep 15 && echo 'K3s agent ${count.index + 1} instalado!'"
    EOT
  }
}

# =============================================================================
# Drop-in systemd: agentes esperam o API do server (porta 6443) responder
# antes de iniciar o k3s-agent. Resolve race condition pos-reboot.
# =============================================================================
resource "local_file" "k3s_agent_wait_dropin" {
  filename        = "${path.module}/generated/k3s-agent-wait.conf"
  file_permission = "0644"
  content         = <<-EOT
    [Service]
    ExecStartPre=/bin/sh -c 'until curl -ks --max-time 5 https://${local.server_ip_clean}:6443/livez >/dev/null 2>&1; do echo "Aguardando k3s server em ${local.server_ip_clean}:6443..."; sleep 5; done'
  EOT
}

resource "null_resource" "k3s_agent_wait_dropin" {
  count = var.agent_count

  depends_on = [
    null_resource.k3s_agent_install,
    local_file.k3s_agent_wait_dropin,
  ]

  triggers = {
    dropin_content = local_file.k3s_agent_wait_dropin.content
    agent_ip       = local.agent_ips_clean[count.index]
  }

  connection {
    type        = "ssh"
    host        = local.agent_ips_clean[count.index]
    user        = var.ssh_user
    private_key = file(local.ssh_private_key)
    timeout     = "2m"
  }

  provisioner "file" {
    source      = local_file.k3s_agent_wait_dropin.filename
    destination = "/tmp/k3s-agent-wait.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/systemd/system/k3s-agent.service.d",
      "sudo mv /tmp/k3s-agent-wait.conf /etc/systemd/system/k3s-agent.service.d/wait-for-server.conf",
      "sudo chmod 644 /etc/systemd/system/k3s-agent.service.d/wait-for-server.conf",
      "sudo systemctl daemon-reload",
      "echo 'Drop-in wait-for-server instalado'",
    ]
  }
}

# =============================================================================
# Gerar Kubeconfig Local
# =============================================================================
resource "null_resource" "kubeconfig" {
  depends_on = [null_resource.k3s_agent_install]

  provisioner "local-exec" {
    command = <<-EOT
      ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${local.ssh_private_key} ${var.ssh_user}@${local.server_ip_clean} 'sudo cat /etc/rancher/k3s/k3s.yaml' | sed 's/127.0.0.1/${local.server_ip_clean}/g' > ${path.module}/generated/kubeconfig.yaml
      echo "Kubeconfig salvo em generated/kubeconfig.yaml"
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/generated/kubeconfig.yaml"
  }
}
