
locals {
  num_of_azs = var.number_of_azs > 2 ? var.number_of_azs : 2
  public_subnets  = [for index in range(local.num_of_azs) : cidrsubnet(aws_vpc.eks.cidr_block, 8, index)]
  private_subnets = [for index in range(local.num_of_azs) : cidrsubnet(aws_vpc.eks.cidr_block, 8, index + 100)]
}

data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "eks" {
  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project}-eks-vpc",
  }
}

# Private & Public Subnets
resource "aws_subnet" "eks_public" {
  count = local.num_of_azs

  vpc_id            = aws_vpc.eks.id
  cidr_block        = local.public_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                     = "${var.project}-eks-public-${count.index}"
    "kubernetes.io/role/elb" = 1
  }

  map_public_ip_on_launch             = true
  private_dns_hostname_type_on_launch = "ip-name"
}

resource "aws_subnet" "eks_private" {
  count = local.num_of_azs

  vpc_id            = aws_vpc.eks.id
  cidr_block        = local.private_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                              = "${var.project}-eks-private-${count.index}"
    "kubernetes.io/role/internal-elb" = 1
  }
  private_dns_hostname_type_on_launch = "ip-name"
}


# Internet Gateway
resource "aws_internet_gateway" "eks" {
  vpc_id = aws_vpc.eks.id

  tags = {
    Name = "${var.project}-eks-igw"
  }
}


# NAT Gateway
resource "aws_nat_gateway" "eks" {
  allocation_id = aws_eip.eks_nat.id
  subnet_id     = aws_subnet.eks_public[0].id

  tags = {
    Name = "${var.project}-eks-nat"
  }
}

resource "aws_eip" "eks_nat" {
  vpc = true

  tags = {
    Name = "${var.project}-eks-eip"
  }
}

# Routing Tables
resource "aws_default_route_table" "default_route_table" {
  default_route_table_id = aws_vpc.eks.default_route_table_id
  tags = {
    Name = "${var.project}-eks-default"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks.id
  }

  tags = {
    Name = "${var.project}-eks-public"
  }
}

resource "aws_route_table_association" "internet_access" {
  count = local.num_of_azs

  subnet_id      = aws_subnet.eks_public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route" "main" {
  route_table_id         = aws_vpc.eks.default_route_table_id
  nat_gateway_id         = aws_nat_gateway.eks.id
  destination_cidr_block = "0.0.0.0/0"
}
