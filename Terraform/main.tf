# Configuration Terraform et Provider AWS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-west-3"
}

# VPC Public
resource "aws_vpc" "public_vpc" {
  cidr_block           = var.public_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "CFT-public-vpc"
  }
}

# Subnet Public
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.public_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true

  tags = {
    Name = "CFT-public-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "public_igw" {
  vpc_id = aws_vpc.public_vpc.id

  tags = {
    Name = "CFT-public-igw"
  }
}

# Table de routage publique
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.public_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public_igw.id
  }

route {
    cidr_block = "10.1.1.0/24"
    gateway_id = aws_vpc_peering_connection.vpc_peering.id
  }
  
  tags = {
    Name = "CFT-public-rt"
  }
}

# Association de la table de routage publique
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# VPC Privé
resource "aws_vpc" "private_vpc" {
  cidr_block           = var.private_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "CFT-private-vpc"
  }
}

# Subnet Privé
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.private_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "eu-west-3a"

  tags = {
    Name = "CFT-private-subnet"
  }
}

# VPC Peering
resource "aws_vpc_peering_connection" "vpc_peering" {
  peer_vpc_id = aws_vpc.private_vpc.id
  vpc_id      = aws_vpc.public_vpc.id
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = {
    Name = "CFT-vpc-peering"
  }
}

# Route pour le peering dans la table publique
resource "aws_route" "public_to_private" {
  route_table_id            = aws_route_table.public_rt.id
  destination_cidr_block    = var.private_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

# Table de routage privée
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.private_vpc.id

  # Route uniquement vers le VPC public via peering
  route {
    cidr_block                = var.public_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  }

  tags = {
    Name = "CFT-private-rt"
  }
}

# Association de la table de routage privée
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# Création de Zone DNS private
resource "aws_route53_zone" "private" {
  name = "tycm2-infra.fr"

    vpc {
    vpc_id = aws_vpc.private_vpc.id
  }

    vpc {
    vpc_id = aws_vpc.public_vpc.id
  }
}

# Enregistrements Route 53
resource "aws_route53_record" "cozy_A" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "cft-cozycloud.tycm2-infra.fr"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.cozycloud.private_ip]
}

resource "aws_route53_record" "cozy_cname" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "*.cft-cozycloud.tycm2-infra.fr"
  type    = "CNAME"
  ttl     = "300"
  records = ["cft-cozycloud.tycm2-infra.fr"]
}

# Security Group pour le bastion
resource "aws_security_group" "bastion_sg" {
  name        = "CFT-bastion-sg"
  description = "Security group for bastion host with OpenVPN"
  vpc_id      = aws_vpc.public_vpc.id

  # SSH depuis Internet
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
    # PING depuis le bastion uniquement
  ingress {
    description = "PING from bastion"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # OpenVPN
  ingress {
    description = "OpenVPN"
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Trafic sortant autorisé vers Internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "CFT-bastion-sg"
  }
}

# Security Group pour Cozycloud
resource "aws_security_group" "cozycloud_sg" {
  name        = "CFT-cozycloud-sg"
  description = "Security group for Cozycloud instance"
  vpc_id      = aws_vpc.private_vpc.id

  # HTTP depuis le VPC public uniquement
  ingress {
    description = "HTTP from public VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.public_vpc_cidr]
  }

  # HTTPS depuis le VPC public uniquement
  ingress {
    description = "HTTPS from public VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.public_vpc_cidr]
  }

  # SSH depuis le bastion uniquement
  ingress {
    description = "SSH from bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.public_subnet_cidr]
  }

  # PING depuis le bastion uniquement
  ingress {
    description = "PING from bastion"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Pas de trafic sortant vers Internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.public_vpc_cidr]  # Uniquement vers le VPC public
  }

  tags = {
    Name = "CFT-cozycloud-sg"
  }
}

# Instance EC2 Bastion
resource "aws_instance" "bastion" {
  ami           = var.bastion_ami
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "CFT-bastion-vpn"
  }
}

# Instance EC2 Cozycloud
resource "aws_instance" "cozycloud" {
  ami           = var.cozycloud_ami
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.private_subnet.id
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.cozycloud_sg.id]

  tags = {
    Name = "CFT-cozycloud"
  }
}
