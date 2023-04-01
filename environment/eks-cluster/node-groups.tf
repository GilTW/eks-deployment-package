resource "aws_eks_node_group" "workers" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project}-${each.key}"
  node_role_arn   = module.eks_workers_role[each.key].arn
  subnet_ids      = local.private_subnet_ids # From control-plane.tf

  scaling_config {
    desired_size = lookup(lookup(each.value, "scaling_config", {}), "desired_size", 1)
    max_size     = lookup(lookup(each.value, "scaling_config", {}), "max_size", 1)
    min_size     = lookup(lookup(each.value, "scaling_config", {}), "min_size", 1)
  }

  ami_type       = lookup(each.value, "ami_type", "AL2_x86_64")
  capacity_type  = lookup(each.value, "capacity_type", "ON_DEMAND")
  disk_size      = lookup(each.value, "disk_size", 20)
  instance_types = lookup(each.value, "instance_types", ["t3.medium"])

  tags = {
    Name = "${var.project}-${each.key}"
  }

  depends_on = [
    module.eks_workers_role
  ]
}

module "eks_workers_role" {
  for_each   = var.node_groups
  source     = "../../shared-modules/iam-service-role"
  identifier = "ec2.amazonaws.com"
  name       = "${var.project}-${each.key}"

  policies = [
    {
      policy_name = "AmazonEKSWorkerNodePolicy"
      policy_type = "MANAGED"
    },
    {
      policy_name = "AmazonEKS_CNI_Policy"
      policy_type = "MANAGED"
    },
    {
      policy_name = "AmazonEC2ContainerRegistryReadOnly"
      policy_type = "MANAGED"
    },
  ]
}
