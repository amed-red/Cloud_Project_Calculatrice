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
