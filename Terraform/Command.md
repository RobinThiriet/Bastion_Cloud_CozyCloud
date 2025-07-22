terraform init
terraform plan
terraform apply
terraform destroy

terraform apply -var "bastion_ami=ami-034be14b62a0b12c7" -var "cozycloud_ami=ami-0f207dc81ec4432ea" -var "key_name=CTF-KeyPair"

sudo scp -i CTF-KeyPair admin@15.237.248.216:/home/admin/CFT.ovpn /mnt/c/Program\ Files/OpenVPN/config