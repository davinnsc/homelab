# =============================================================================
# Proxmox Connection
# =============================================================================
variable "proxmox_url" {
  description = "URL da API do Proxmox (ex: https://192.168.15.6:8006)"
  type        = string
}

variable "proxmox_user" {
  description = "Usuario da API do Proxmox (ex: root@pam)"
  type        = string
}

variable "proxmox_password" {
  description = "Senha do usuario Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Nome do node Proxmox"
  type        = string
  default     = "proxmox"
}

variable "proxmox_tls_insecure" {
  description = "Ignorar verificacao TLS (self-signed certs)"
  type        = bool
  default     = true
}

# =============================================================================
# Template
# =============================================================================
variable "template_vmid" {
  description = "VMID do template cloud-init"
  type        = number
  default     = 9000
}

# =============================================================================
# Rede
# =============================================================================
variable "gateway" {
  description = "Gateway da rede"
  type        = string
  default     = "192.168.15.1"
}

variable "nameservers" {
  description = "Servidores DNS (lista)"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "search_domain" {
  description = "Dominio de busca DNS"
  type        = string
  default     = "local"
}

variable "bridge" {
  description = "Bridge de rede do Proxmox"
  type        = string
  default     = "vmbr0"
}

# =============================================================================
# SSH
# =============================================================================
variable "ssh_user" {
  description = "Usuario SSH para cloud-init"
  type        = string
  default     = "ubuntu"
}

variable "ssh_private_key_path" {
  description = "Caminho da chave SSH privada"
  type        = string
  default     = "~/.ssh/id_homelab"
}

variable "ssh_public_key_path" {
  description = "Caminho da chave SSH publica"
  type        = string
  default     = "~/.ssh/id_homelab.pub"
}

# =============================================================================
# K3s Server
# =============================================================================
variable "server_vmid" {
  description = "VMID do k3s server (0 = auto)"
  type        = number
  default     = 200
}

variable "server_name" {
  description = "Nome da VM do k3s server"
  type        = string
  default     = "homelab-k3s-dev-server-1"
}

variable "server_cores" {
  description = "Numero de cores do server"
  type        = number
  default     = 2
}

variable "server_memory" {
  description = "RAM do server em MB"
  type        = number
  default     = 2048
}

variable "server_disk_size" {
  description = "Tamanho do disco do server em GB"
  type        = number
  default     = 20
}

variable "server_ip" {
  description = "IP estatico do k3s server (CIDR)"
  type        = string
  default     = "192.168.15.201/24"
}

variable "server_storage" {
  description = "Storage do Proxmox para o disco do server"
  type        = string
  default     = "local-lvm"
}

# =============================================================================
# K3s Agents
# =============================================================================
variable "agent_count" {
  description = "Numero de agents k3s"
  type        = number
  default     = 2
}

variable "agent_vmids" {
  description = "VMIDs dos agents (lista)"
  type        = list(number)
  default     = [300, 301]
}

variable "agent_names" {
  description = "Nomes das VMs dos agents"
  type        = list(string)
  default     = ["homelab-k3s-dev-agent-1", "homelab-k3s-dev-agent-2"]
}

variable "agent_cores" {
  description = "Numero de cores de cada agent"
  type        = number
  default     = 2
}

variable "agent_memory" {
  description = "RAM de cada agent em MB"
  type        = number
  default     = 3072
}

variable "agent_disk_size" {
  description = "Tamanho do disco de cada agent em GB"
  type        = number
  default     = 30
}

variable "agent_ips" {
  description = "IPs estaticos dos agents (CIDR)"
  type        = list(string)
  default     = ["192.168.15.211/24", "192.168.15.212/24"]
}

variable "agent_storage" {
  description = "Storage do Proxmox para o disco dos agents"
  type        = string
  default     = "local-lvm"
}

# =============================================================================
# K3s
# =============================================================================
variable "k3s_version" {
  description = "Versao do k3s (vazio = latest)"
  type        = string
  default     = ""
}
