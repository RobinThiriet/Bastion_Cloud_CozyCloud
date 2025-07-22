# Documentation Infrastructure AWS avec Terraform

## Table des Matières
1. [Objectif du Projet](#objectif-du-projet)
2. [Architecture](#architecture)
3. [Prérequis](#prérequis)
4. [Déploiement de l'Infrastructure](#déploiement-de-l'infrastructure)
5. [Configuration Post-Déploiement](#configuration-post-déploiement)
6. [Gestion des AMIs](#gestion-des-amis)
7. [Sécurité](#sécurité)
8. [Bonnes Pratiques](#bonnes-pratiques)

## Objectif du Projet

Ce projet vise à créer une infrastructure AWS sécurisée pour héberger CozyCloud avec les caractéristiques suivantes :

- Architecture multi-VPC avec isolation réseau
- Bastion host pour l'accès sécurisé
- Déploiement automatisé via Terraform
- Communication sécurisée via VPN et peering
- Préfixe "CFT-" pour toutes les ressources
- Déploiement en région eu-west-3 (Paris)

## Architecture

### Composants Réseau
1. **VPC Public (Bastion)**
   - CIDR: 10.0.0.0/16
   - Subnet public: 10.0.1.0/24
   - Internet Gateway
   - Route table publique

2. **VPC Privé (CozyCloud)**
   - CIDR: 10.1.0.0/16
   - Subnet privé: 10.1.1.0/24
   - Routes uniquement vers le VPC public

3. **Interconnexion**
   - VPC Peering entre les deux VPCs
   - VPN pour l'accès sécurisé
   - Security Groups dédiés

### Instances EC2
1. **Bastion Host**
   - t2.micro dans le subnet public
   - OpenVPN préconfiguré
   - IP publique

2. **Serveur CozyCloud**
   - t2.medium dans le subnet privé
   - CozyCloud et OnlyOffice préinstallés
   - Pas d'IP publique

## Prérequis

### Outils Requis
- AWS CLI v2+
- Terraform >= 1.2.0
- OpenVPN Client
- SSH Client

### Accès AWS
- Compte AWS avec permissions administrateur
- Credentials AWS configurés
- Key pair AWS créée et téléchargée

### Variables Requises
```hcl
# variable.tf
key_name      = "CFT-KeyPair"
bastion_ami   = "ami-08fb0cc3789468f4d"  # Ubuntu 22.04 LTS
cozycloud_ami = "ami-xxxxx"               # AMI personnalisée avec CozyCloud
public_vpc_cidr = 10.0.0.0/16
private_vpc_cid = 10.1.0.0/16
public_subnet_cidr = 10.0.1.0/24
private_subnet_cidr = 10.1.1.0/24

```

## Déploiement de l'Infrastructure

### 1. Préparation
```bash
# Cloner le repository
git clone [URL_REPO]
cd [REPO_NAME]

# Initialiser Terraform
terraform init
```

### 2. Configuration SSH
Créez ou modifiez `~/.ssh/config`:
```plaintext
Host CFT-Bastion
    HostName [BASTION_PUBLIC_IP]
    User admin
    IdentityFile ~/.ssh/CFT-KeyPair.pem

Host CFT-CozyCloud
    HostName [COZYCLOUD_PRIVATE_IP]
    User admin
    IdentityFile ~/.ssh/CFT-KeyPair.pem
```

### 3. Déploiement
```bash
# Vérifier le plan
terraform plan

# Appliquer les changements
terraform apply
```

## Configuration Post-Déploiement

### 1. Configuration du Bastion
```bash
# Connexion au bastion
ssh CFT-Bastion

# Installation d'OpenVPN
sudo apt update
sudo apt install -y openvpn
```

### 2. Configuration de CozyCloud
```bash
# Connexion à l'instance CozyCloud
ssh CFT-CozyCloud

# Vérification des services
sudo systemctl status cozy-stack
sudo systemctl status onlyoffice
```

## Gestion des AMIs

### Création des AMIs
1. **AMI Bastion**
   ```bash
   aws ec2 create-image \
     --instance-id [BASTION_ID] \
     --name "CFT-Bastion-AMI" \
     --description "Bastion avec OpenVPN"
   ```

2. **AMI CozyCloud**
   ```bash
   aws ec2 create-image \
     --instance-id [COZYCLOUD_ID] \
     --name "CFT-CozyCloud-AMI" \
     --description "CozyCloud avec OnlyOffice"
   ```

## Sécurité

### Règles de Security Group
1. **Bastion SG**
   - Entrant: SSH (22), OpenVPN (1194)
   - Sortant: Tout

2. **CozyCloud SG**
   - Entrant: SSH (22, Bastion), HTTP (80), HTTPS (443)
   - Sortant: Uniquement vers VPC public

### Bonnes Pratiques
- Rotation régulière des clés SSH
- Mise à jour régulière des AMIs
- Monitoring des logs de connexion
- Sauvegarde régulière des données CozyCloud
---
*Documentation maintenue par l'équipe Infrastructure*
