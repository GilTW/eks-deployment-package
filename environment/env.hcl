locals {
  deployment_region = "eu-central-1"
  project_name      = "opsfleet"
}


# Managing the backend for all of the components containing "terragrunt.hcl"
remote_state {
  backend = "s3"
  config = {
    bucket         = "${local.project_name}-infra-tf"
    key            = "${basename(get_terragrunt_dir())}/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "tf-lock-table"
  }
}

generate "providers" {
  path      = "tf-settings.tf"
  if_exists = "skip"
  contents = templatefile("${get_parent_terragrunt_dir()}/..//templates/tf-settings.tf.tpl", {
    aws = {
      version = "4.52.0"
      region  = local.deployment_region
    }
  })
}

inputs = {
  ### Common ###
  project = local.project_name

  ### Networking Component (Optional - See README.md) ###
  vpc_cidr      = "192.168.0.0/16"
  number_of_azs = 2

  ### EKS Cluster Component ###
  cluster_name = "simple-eks"
  k8s_version  = "1.25"
  node_groups = {
    "simple-ng" : {
      ami_type       = "AL2_x86_64" # AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM
      capacity_type  = "ON_DEMAND"  # ON_DEMAND, SPOT
      disk_size      = 20
      instance_types = ["t3.medium"]
      scaling_config = {
        desired_size = 1
        max_size     = 1
        min_size     = 1
      }
    }
  }

  # If you are not using the Networking component you must set the public and private subnet ids with at least 2 subent ids in each.
  # Make sure you provide subnets with at least 6 free ips but of course it is recommended to provide much larger subnets.
  # Also make sure that the private subnets have access to a NAT if you intend to allow outbound connections from the node groups' machines.
  # public_subnet_ids = []
  # private_subnet_ids = []

  # Additional cidrs to add statically, by default, the terraform invoker gets access by the component
  cluster_public_access_cidrs = []

  ### EKS Service Accounts Component ###
  eks_service_accounts = {
    "service-x-sa" : {
      k8s_namespace = "default"
      iam_policies = [
        {
          policy_name = "S3Permissions"
          policy_type = "CUSTOM_INLINE"
          custom_permissions = {
            effect    = "Allow"
            actions   = ["s3:PutObject"]
            resources = ["arn:aws:s3:::${local.project_name}-infra-tf"]
          }
        }
      ]
    }
  }
}
