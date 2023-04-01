include {
  path = find_in_parent_folders("env.hcl")
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    public_subnets = [{id = null}]
    private_subnets = [{id = null}]
  }
}

inputs = {
  public_subnet_ids_dep = dependency.networking.outputs.public_subnets[*].id
  private_subnet_ids_dep = dependency.networking.outputs.private_subnets[*].id
}
