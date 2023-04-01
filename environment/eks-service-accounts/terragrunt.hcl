include {
  path = find_in_parent_folders("env.hcl")
}

dependency "eks_cluster" {
  config_path = "../eks-cluster"

  mock_outputs = {
    oidc_issuer = "https://oidc.eks.us-east-1.amazonaws.com/id/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    cluster_name = "just-mock"
  }
}

inputs = {
  eks_oidc_issuer_dep = dependency.eks_cluster.outputs.oidc_issuer
  cluster_name_dep = dependency.eks_cluster.outputs.cluster_name
}
