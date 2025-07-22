output "bastion_public_ip" {
  description = "IP publique du bastion/serveur VPN"
  value       = aws_instance.bastion.public_ip
}

output "cozycloud_private_ip" {
  description = "IP privée de l'instance Cozycloud"
  value       = aws_instance.cozycloud.private_ip
}
