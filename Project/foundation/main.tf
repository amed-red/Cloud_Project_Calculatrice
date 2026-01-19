############################################
# 1. Provider AWS
############################################
# Indique à Terraform quel fournisseur cloud utiliser
# et dans quelle région déployer les ressources.
provider "aws" {
  region = "eu-west-3" # Région Paris
}

############################################
# 2. Virtual Private Cloud (VPC)
############################################
# Création d’un réseau privé isolé dans AWS
# 10.0.0.0/16 permet jusqu’à 65 536 adresses IP
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc-examen"
  }
}

############################################
# 3. Internet Gateway
############################################
# Permet aux ressources du VPC d’accéder à Internet
# (obligatoire pour un cluster EKS public)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw-examen"
  }
}

############################################
# 4. Table de routage
############################################
# Définit les règles de routage du VPC
# Ici, tout le trafic sortant (0.0.0.0/0)
# passe par l’Internet Gateway
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

############################################
# 5. Subnet publique A
############################################
# Sous-réseau public dans la zone eu-west-3a
# map_public_ip_on_launch permet d’attribuer
# automatiquement une IP publique aux ressources
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-examen-a"
  }
}

############################################
# 6. Subnet publique B
############################################
# Deuxième sous-réseau dans une autre zone
# (recommandé pour la haute disponibilité EKS)
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-3b"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-examen-b"
  }
}
