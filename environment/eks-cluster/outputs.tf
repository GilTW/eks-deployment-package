output "oidc_issuer" {
  value = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_name" {
  value = aws_eks_cluster.main.name
}
