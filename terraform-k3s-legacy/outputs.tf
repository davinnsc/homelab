output "server_ip" {
  description = "IP do k3s server"
  value       = local.server_ip_clean
}

output "agent_ips" {
  description = "IPs dos k3s agents"
  value       = local.agent_ips_clean
}

output "kubeconfig_path" {
  description = "Caminho do kubeconfig gerado"
  value       = "${abspath(path.module)}/generated/kubeconfig.yaml"
}

output "kubeconfig_usage" {
  description = "Comando para usar o kubeconfig"
  value       = "export KUBECONFIG=${abspath(path.module)}/generated/kubeconfig.yaml"
}
