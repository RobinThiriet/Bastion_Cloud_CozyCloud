# Variables pour les VPCs
variable "public_vpc_cidr" {
  description = "CIDR du VPC public"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_vpc_cidr" {
  description = "CIDR du VPC privé"
  type        = string
  default     = "10.1.0.0/16"
}

# Variables pour les Subnets
variable "public_subnet_cidr" {
  description = "CIDR du subnet public"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR du subnet privé"
  type        = string
  default     = "10.1.1.0/24"
}

# Variables pour les instances EC2
variable "key_name" {
  description = "CTF-KeyPair"
  type        = string
  default     = "CTF-KeyPair"
}

variable "bastion_ami" {
  description = "ID de l'AMI pour le bastion"
  type        = string
  default     = "ami-0b8f5a447f628c081"
}

variable "cozycloud_ami" {
  description = "ID de l'AMI pour Cozycloud"
  type        = string
  default     = "ami-0f207dc81ec4432ea"
}
