# Set open IDC provider
data "tls_certificate" "eks_cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_to_iam" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_cluster.certificates.0.sha1_fingerprint]
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}