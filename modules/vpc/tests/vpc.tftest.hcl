mock_provider "aws" {}

variables {
  project = "anysource"
  environment = "production"
  name = "anysource-vpc"
  region = "us-east-1"
  region_az = ["us-east-1a", "us-east-1b", "us-east-1c"]
  vpc_cidr = "10.0.0.0/16"
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  private_subnet_tags = {
    Type = "Private"
  }
  public_subnet_tags = {
    Type = "Public"
  }
}

run "vpc_basic_configuration" {
  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPC should have correct CIDR block"
  }

  assert {
    condition     = aws_vpc.main.enable_dns_hostnames == true
    error_message = "VPC should have DNS hostnames enabled"
  }

  assert {
    condition     = aws_vpc.main.enable_dns_support == true
    error_message = "VPC should have DNS support enabled"
  }

  assert {
    condition     = aws_vpc.main.tags.Name == "anysource-production"
    error_message = "VPC should have correct Name tag"
  }
}

run "internet_gateway_configuration" {
  assert {
    condition     = aws_internet_gateway.main.vpc_id == aws_vpc.main.id
    error_message = "Internet Gateway should be attached to the VPC"
  }

  assert {
    condition     = aws_internet_gateway.main.tags.Name == "anysource-production"
    error_message = "Internet Gateway should have correct Name tag"
  }

  assert {
    condition     = aws_internet_gateway.main.tags.environment == "production"
    error_message = "Internet Gateway should have correct environment tag"
  }

  assert {
    condition     = aws_internet_gateway.main.tags.name == "anysource"
    error_message = "Internet Gateway should have correct name tag"
  }
}

run "public_subnets_configuration" {
  assert {
    condition     = length(aws_subnet.public) == 3
    error_message = "Should create 3 public subnets"
  }

  assert {
    condition     = aws_subnet.public[0].cidr_block == "10.0.1.0/24"
    error_message = "First public subnet should have correct CIDR"
  }

  assert {
    condition     = aws_subnet.public[1].cidr_block == "10.0.2.0/24"
    error_message = "Second public subnet should have correct CIDR"
  }

  assert {
    condition     = aws_subnet.public[2].cidr_block == "10.0.3.0/24"
    error_message = "Third public subnet should have correct CIDR"
  }

  assert {
    condition     = aws_subnet.public[0].map_public_ip_on_launch == true
    error_message = "Public subnets should map public IP on launch"
  }

  assert {
    condition     = aws_subnet.public[0].availability_zone == "us-east-1a"
    error_message = "First public subnet should be in us-east-1a"
  }

  assert {
    condition     = aws_subnet.public[1].availability_zone == "us-east-1b"
    error_message = "Second public subnet should be in us-east-1b"
  }

  assert {
    condition     = aws_subnet.public[2].availability_zone == "us-east-1c"
    error_message = "Third public subnet should be in us-east-1c"
  }
}

run "private_subnets_configuration" {
  assert {
    condition     = length(aws_subnet.private) == 3
    error_message = "Should create 3 private subnets"
  }

  assert {
    condition     = aws_subnet.private[0].cidr_block == "10.0.11.0/24"
    error_message = "First private subnet should have correct CIDR"
  }

  assert {
    condition     = aws_subnet.private[1].cidr_block == "10.0.12.0/24"
    error_message = "Second private subnet should have correct CIDR"
  }

  assert {
    condition     = aws_subnet.private[2].cidr_block == "10.0.13.0/24"
    error_message = "Third private subnet should have correct CIDR"
  }

  assert {
    condition     = aws_subnet.private[0].map_public_ip_on_launch == false
    error_message = "Private subnets should not map public IP on launch"
  }

  assert {
    condition     = aws_subnet.private[0].availability_zone == "us-east-1a"
    error_message = "First private subnet should be in us-east-1a"
  }
}

run "subnet_tags_configuration" {
  assert {
    condition     = aws_subnet.public[0].tags.Name == "anysource-production-public-us-east-1a"
    error_message = "Public subnet should have correct Name tag"
  }

  assert {
    condition     = aws_subnet.private[0].tags.Name == "anysource-production-private-us-east-1a"
    error_message = "Private subnet should have correct Name tag"
  }

  assert {
    condition     = aws_subnet.public[0].tags.environment == "production"
    error_message = "Public subnet should have environment tag"
  }

  assert {
    condition     = aws_subnet.public[0].tags.name == "anysource"
    error_message = "Public subnet should have name tag"
  }

  assert {
    condition     = aws_subnet.public[0].tags.Type == "Public"
    error_message = "Public subnet should have Type tag from public_subnet_tags"
  }

  assert {
    condition     = aws_subnet.private[0].tags.Type == "Private"
    error_message = "Private subnet should have Type tag from private_subnet_tags"
  }
}

run "elastic_ips_configuration" {
  assert {
    condition     = length(aws_eip.nat) == 3
    error_message = "Should create 3 Elastic IPs for NAT gateways"
  }

  assert {
    condition     = aws_eip.nat[0].domain == "vpc"
    error_message = "Elastic IP should be in VPC domain"
  }

  assert {
    condition     = aws_eip.nat[0].tags.Name == "anysource-production-us-east-1a"
    error_message = "Elastic IP should have correct Name tag"
  }

  assert {
    condition     = aws_eip.nat[0].tags.environment == "production"
    error_message = "Elastic IP should have environment tag"
  }

  assert {
    condition     = aws_eip.nat[0].tags.name == "anysource"
    error_message = "Elastic IP should have name tag"
  }
}

run "nat_gateways_configuration" {
  assert {
    condition     = length(aws_nat_gateway.nat_gw) == 3
    error_message = "Should create 3 NAT gateways"
  }

  assert {
    condition     = aws_nat_gateway.nat_gw[0].allocation_id == aws_eip.nat[0].id
    error_message = "First NAT gateway should use first Elastic IP"
  }

  assert {
    condition     = aws_nat_gateway.nat_gw[0].subnet_id == aws_subnet.public[0].id
    error_message = "First NAT gateway should be in first public subnet"
  }

  assert {
    condition     = aws_nat_gateway.nat_gw[0].tags.Name == "anysource-production-us-east-1a"
    error_message = "NAT gateway should have correct Name tag"
  }

  assert {
    condition     = aws_nat_gateway.nat_gw[1].subnet_id == aws_subnet.public[1].id
    error_message = "Second NAT gateway should be in second public subnet"
  }

  assert {
    condition     = aws_nat_gateway.nat_gw[2].subnet_id == aws_subnet.public[2].id
    error_message = "Third NAT gateway should be in third public subnet"
  }
}

run "public_route_table_configuration" {
  assert {
    condition     = aws_route_table.public.vpc_id == aws_vpc.main.id
    error_message = "Public route table should be in the VPC"
  }

  assert {
    condition     = contains([for route in aws_route_table.public.route : route.cidr_block], "0.0.0.0/0")
    error_message = "Public route table should have default route"
  }

  assert {
    condition     = contains([for route in aws_route_table.public.route : route.gateway_id], aws_internet_gateway.main.id)
    error_message = "Public route table should route to Internet Gateway"
  }

  assert {
    condition     = aws_route_table.public.tags.Name == "anysource-production-public"
    error_message = "Public route table should have correct Name tag"
  }
}

run "private_route_tables_configuration" {
  assert {
    condition     = length(aws_route_table.private) == 3
    error_message = "Should create 3 private route tables"
  }

  assert {
    condition     = aws_route_table.private[0].vpc_id == aws_vpc.main.id
    error_message = "Private route table should be in the VPC"
  }

  assert {
    condition     = contains([for route in aws_route_table.private[0].route : route.cidr_block], "0.0.0.0/0")
    error_message = "Private route table should have default route"
  }

  assert {
    condition     = contains([for route in aws_route_table.private[0].route : route.nat_gateway_id], aws_nat_gateway.nat_gw[0].id)
    error_message = "First private route table should route to first NAT gateway"
  }

  assert {
    condition     = aws_route_table.private[0].tags.Name == "anysource-production-private-us-east-1a"
    error_message = "Private route table should have correct Name tag"
  }
}

run "route_table_associations" {
  assert {
    condition     = length(aws_route_table_association.public) == 3
    error_message = "Should create 3 public route table associations"
  }

  assert {
    condition     = length(aws_route_table_association.private) == 3
    error_message = "Should create 3 private route table associations"
  }

  assert {
    condition     = aws_route_table_association.public[0].subnet_id == aws_subnet.public[0].id
    error_message = "First public subnet should be associated with public route table"
  }

  assert {
    condition     = aws_route_table_association.public[0].route_table_id == aws_route_table.public.id
    error_message = "Public association should reference public route table"
  }

  assert {
    condition     = aws_route_table_association.private[0].subnet_id == aws_subnet.private[0].id
    error_message = "First private subnet should be associated with first private route table"
  }

  assert {
    condition     = aws_route_table_association.private[0].route_table_id == aws_route_table.private[0].id
    error_message = "Private association should reference corresponding private route table"
  }
}

run "module_outputs" {
  assert {
    condition     = output.vpc_id == aws_vpc.main.id
    error_message = "VPC ID output should match resource"
  }

  assert {
    condition     = length(output.private_subnets) == 3
    error_message = "Private subnets output should contain 3 subnet IDs"
  }

  assert {
    condition     = length(output.public_subnets) == 3
    error_message = "Public subnets output should contain 3 subnet IDs"
  }

  assert {
    condition     = contains(output.private_subnets, aws_subnet.private[0].id)
    error_message = "Private subnets output should contain first private subnet ID"
  }

  assert {
    condition     = contains(output.public_subnets, aws_subnet.public[0].id)
    error_message = "Public subnets output should contain first public subnet ID"
  }
}

run "staging_environment" {
  variables {
    environment = "stg"
  }

  assert {
    condition     = aws_vpc.main.tags.Name == "anysource-stg"
    error_message = "VPC should use staging environment in name"
  }

  assert {
    condition     = aws_internet_gateway.main.tags.Name == "anysource-stg"
    error_message = "Internet Gateway should use staging environment in name"
  }

  assert {
    condition     = aws_subnet.public[0].tags.Name == "anysource-stg-public-us-east-1a"
    error_message = "Public subnet should use staging environment in name"
  }

  assert {
    condition     = aws_route_table.public.tags.Name == "anysource-stg-public"
    error_message = "Public route table should use staging environment in name"
  }
}

run "single_availability_zone" {
  variables {
    region_az = ["us-east-1a"]
    public_subnets = ["10.0.1.0/24"]
    private_subnets = ["10.0.11.0/24"]
  }

  assert {
    condition     = length(aws_subnet.public) == 1
    error_message = "Should create 1 public subnet for single AZ"
  }

  assert {
    condition     = length(aws_subnet.private) == 1
    error_message = "Should create 1 private subnet for single AZ"
  }

  assert {
    condition     = length(aws_eip.nat) == 1
    error_message = "Should create 1 Elastic IP for single AZ"
  }

  assert {
    condition     = length(aws_nat_gateway.nat_gw) == 1
    error_message = "Should create 1 NAT gateway for single AZ"
  }

  assert {
    condition     = length(aws_route_table.private) == 1
    error_message = "Should create 1 private route table for single AZ"
  }
}

run "different_project_and_cidr" {
  variables {
    project = "testproject"
    vpc_cidr = "172.16.0.0/16"
    public_subnets = ["172.16.1.0/24", "172.16.2.0/24"]
    private_subnets = ["172.16.11.0/24", "172.16.12.0/24"]
    region_az = ["us-east-1a", "us-east-1b"]
  }

  assert {
    condition     = aws_vpc.main.cidr_block == "172.16.0.0/16"
    error_message = "VPC should use different CIDR block"
  }

  assert {
    condition     = aws_vpc.main.tags.Name == "testproject-production"
    error_message = "VPC should use different project name"
  }

  assert {
    condition     = aws_subnet.public[0].cidr_block == "172.16.1.0/24"
    error_message = "Public subnet should use different CIDR"
  }

  assert {
    condition     = aws_subnet.private[0].cidr_block == "172.16.11.0/24"
    error_message = "Private subnet should use different CIDR"
  }

  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "Should create 2 public subnets for 2 AZs"
  }

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Should create 2 private subnets for 2 AZs"
  }
}