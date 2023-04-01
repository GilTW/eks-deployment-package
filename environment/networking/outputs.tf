output "public_subnets" {
  value = aws_subnet.eks_public
}

output "private_subnets" {
  value = aws_subnet.eks_private
}