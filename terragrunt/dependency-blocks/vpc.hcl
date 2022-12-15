skip = true

dependency "vpc" {
  config_path = "${get_original_terragrunt_dir()}/../vpc"

  mock_outputs = {
    vpc_id = "vpc-00000000"
    private_subnets = [
      "subnet-00000000",
      "subnet-00000001",
      "subnet-00000002",
    ]
    public_subnets = [
      "subnet-00000003",
      "subnet-00000004",
      "subnet-00000005",
    ]
    intra_subnets = [
      "subnet-00000006",
      "subnet-00000007",
      "subnet-00000008",
    ]
    private_subnets_cidr_blocks = [
      "192.168.0.0/16",
      "10.0.0.0/8",
      "172.16.0.0/12"
    ]
    intra_subnets_cidr_blocks = [
      "192.168.0.0/16",
      "10.0.0.0/8",
      "172.16.0.0/12"
    ]
    intra_route_table_ids     = []
    private_route_table_ids   = []
    public_route_table_ids    = []
    default_security_group_id = "sg-00000000"
  }
}
