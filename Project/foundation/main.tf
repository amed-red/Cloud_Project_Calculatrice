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

############################################
# 7. Association des subnets à la table de routage
############################################
# Permet aux subnets d’utiliser la route vers Internet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.rt.id
}

############################################
# 8. Elastic Container Registry (ECR)
############################################
# Registre Docker privé pour stocker les images
# qui seront utilisées par le cluster EKS
resource "aws_ecr_repository" "app" {
  name = "repo-examen"
}


############################################
# 9. Rôle IAM pour EKS
############################################
# Rôle que le service EKS va assumer
# pour gérer les ressources AWS
resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role-examen"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

############################################
# 10. Attachement des policies IAM nécessaires
############################################
# Autorise EKS à créer et gérer le cluster
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Autorise EKS à gérer les ressources réseau du VPC
resource "aws_iam_role_policy_attachment" "eks_vpc_controller" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

############################################
# 11. Création du cluster EKS
############################################
# Création du control plane Kubernetes
# Le cluster est déployé dans les deux subnets
resource "aws_eks_cluster" "main" {
  name      = "cluster-examen"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.public_a.id,
      aws_subnet.public_b.id
    ]
  }

  # Garantit que les policies IAM sont bien attachées
  # avant la création du cluster
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_controller
  ]
}
