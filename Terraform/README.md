# Projet Infrastructure Cloud - CozyCloud Sécurisé

## 🚀 **Résumé**
Déploiement sécurisé d’une infrastructure cloud sur **AWS** avec **Terraform**, incluant :
- Un **bastion** dans un **VPC public** (accès SSH et VPN).
- Un **serveur CozyCloud avec OnlyOffice** dans un **VPC privé**.
- Une **connexion entre les deux VPCs** via **VPC Peering**.

## 🏗️ **Architecture**
- **VPC Public (Bastion)** : Subnet public, **Internet Gateway**, accès SSH/VPN (ports 22/1194).
- **VPC Privé (CozyCloud)** : Subnet privé, aucun accès direct à Internet, accès via **bastion**.
- **Sécurité** : Groupes de sécurité restrictifs, **VPN obligatoire** pour accéder à CozyCloud.

## 🔧 **Prérequis**
- **AWS CLI** et **Terraform** installés.
- **Clé SSH AWS** pour l’accès au bastion.
- **AMI préparées** pour :
  - Bastion (avec OpenVPN)
  - CozyCloud (avec OnlyOffice)

## 📂 **Structure du Projet**
```plaintext
.
├── main.tf        # Définition des ressources AWS
├── variables.tf   # Déclaration des variables
└── outputs.tf     # Informations de sortie
```
Toutes les ressources sont préfixées avec **"CFT-"**.

## 🚀 **Déploiement**
1. **Cloner le projet**  
   ```bash
   git clone https://github.com/GuillaumeFind/M1Ynov-CFT/
   cd M1Ynov-CFT
   ```
2. **Déployer avec Terraform**  
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## 🔒 **Sécurité**
- **Accès SSH uniquement sur le bastion**.
- **VPN requis** pour accéder au serveur CozyCloud.
- **Trafic restreint** entre les VPCs (HTTP/HTTPS uniquement).

---

📌 **Projet réalisé dans le cadre du module Infrastructure Cloud - M1 Ynov**.
