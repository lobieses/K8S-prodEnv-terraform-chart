data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "lobieses-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "Name"                                        = "public-subnet-${var.deployment_prefix}"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"   # Need for correct work aws ALB controller
  }

  private_subnet_tags = {
    "Name"                                        = "private-subnet-${var.deployment_prefix}"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"    # Need for correct work aws ALB controller
  }

  public_route_table_tags = {
    "Name" = "public-route-table-${var.deployment_prefix}"
  }

  private_route_table_tags = {
    "Name" = "private-route-table-${var.deployment_prefix}"
  }
}
