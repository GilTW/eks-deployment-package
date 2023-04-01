terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.52.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.19.0"
    }
  }

  backend "s3" {}
}

data "aws_eks_cluster" "default" {
  name = var.cluster_name_dep
}

data "aws_eks_cluster_auth" "default" {
  name = var.cluster_name_dep
}

provider "aws" {
  region = "eu-central-1"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.default.token
}
