mock_provider "aws" {
  mock_resource "aws_security_group" {
    defaults = {
      id = "sg-12345678"
    }
  }
}

variables {
  name = "anysource-production-sg"
  description = "Security group for anysource production environment"
  vpc_id = "vpc-12345678"
  ingress_rules = [
    {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      cidr_blocks     = ["10.0.0.0/16"]
      security_groups = []
    },
    {
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    },
    {
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      cidr_blocks     = ["10.0.1.0/24"]
      security_groups = ["sg-admin"]
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp" 
      cidr_blocks = ["10.0.0.0/8"]
    }
  ]
}

run "security_group_basic_configuration" {
  assert {
    condition     = aws_security_group.security_group.name == "anysource-production-sg"
    error_message = "Security group should have correct name"
  }

  assert {
    condition     = aws_security_group.security_group.description == "Security group for anysource production environment"
    error_message = "Security group should have correct description"
  }

  assert {
    condition     = aws_security_group.security_group.vpc_id == "vpc-12345678"
    error_message = "Security group should be in correct VPC"
  }
}

run "security_group_ingress_rules" {
  assert {
    condition     = length(aws_security_group.security_group.ingress) == 3
    error_message = "Security group should have exactly 3 ingress rules"
  }

  assert {
    condition     = contains([for rule in aws_security_group.security_group.ingress : rule.from_port], 80)
    error_message = "Security group should have HTTP port 80 ingress rule"
  }

  assert {
    condition     = contains([for rule in aws_security_group.security_group.ingress : rule.to_port], 80)
    error_message = "Security group should have HTTP port 80 to_port in ingress rule"
  }

  assert {
    condition     = contains([for rule in aws_security_group.security_group.ingress : rule.from_port], 443)
    error_message = "Security group should have HTTPS port 443 ingress rule"
  }

  assert {
    condition     = contains([for rule in aws_security_group.security_group.ingress : rule.to_port], 443)
    error_message = "Security group should have HTTPS port 443 to_port in ingress rule"
  }

  assert {
    condition     = contains([for rule in aws_security_group.security_group.ingress : rule.from_port], 22)
    error_message = "Security group should have SSH port 22 ingress rule"
  }

  assert {
    condition     = contains([for rule in aws_security_group.security_group.ingress : rule.protocol], "tcp")
    error_message = "Security group should have TCP protocol in ingress rules"
  }
}

run "security_group_ingress_cidr_blocks" {
  assert {
    condition     = anytrue([
      for rule in aws_security_group.security_group.ingress : 
      contains(rule.cidr_blocks, "10.0.0.0/16")
    ])
    error_message = "Security group should allow access from VPC CIDR 10.0.0.0/16"
  }

  assert {
    condition     = anytrue([
      for rule in aws_security_group.security_group.ingress : 
      contains(rule.cidr_blocks, "0.0.0.0/0")
    ])
    error_message = "Security group should allow HTTPS access from anywhere"
  }

  assert {
    condition     = anytrue([
      for rule in aws_security_group.security_group.ingress : 
      contains(rule.cidr_blocks, "10.0.1.0/24")
    ])
    error_message = "Security group should allow SSH access from specific subnet"
  }
}

run "security_group_ingress_security_groups" {
  assert {
    condition     = anytrue([
      for rule in aws_security_group.security_group.ingress : 
      contains(rule.security_groups, "sg-admin")
    ])
    error_message = "Security group should reference admin security group for SSH access"
  }
}

run "security_group_egress_rules" {
  assert {
    condition     = length(aws_security_group.security_group.egress) == 2
    error_message = "Security group should have exactly 2 egress rules"
  }

  assert {
    condition     = contains([for rule in aws_security_group.security_group.egress : rule.from_port], 0)
    error_message = "Security group should have unrestricted egress rule (port 0)"
  }

  assert {
    condition     = contains([for rule in aws_security_group.security_group.egress : rule.to_port], 0)
    error_message = "Security group should have unrestricted egress rule (to_port 0)"
  }

  assert {
    condition     = contains([for rule in aws_security_group.security_group.egress : rule.protocol], "-1")
    error_message = "Security group should have all protocols allowed in egress (-1)"
  }

  assert {
    condition     = contains([for rule in aws_security_group.security_group.egress : rule.from_port], 443)
    error_message = "Security group should have HTTPS port 443 egress rule"
  }

  assert {
    condition     = contains([for rule in aws_security_group.security_group.egress : rule.protocol], "tcp")
    error_message = "Security group should have TCP protocol in egress rules"
  }
}

run "security_group_egress_cidr_blocks" {
  assert {
    condition     = anytrue([
      for rule in aws_security_group.security_group.egress : 
      contains(rule.cidr_blocks, "0.0.0.0/0")
    ])
    error_message = "Security group should allow unrestricted egress to anywhere"
  }

  assert {
    condition     = anytrue([
      for rule in aws_security_group.security_group.egress : 
      contains(rule.cidr_blocks, "10.0.0.0/8")
    ])
    error_message = "Security group should allow HTTPS egress to private networks"
  }
}

run "module_outputs" {
  assert {
    condition     = output.security_group_id == aws_security_group.security_group.id
    error_message = "Security group ID output should match resource ID"
  }
}

run "minimal_security_group" {
  variables {
    name = "minimal-sg"
    description = "Minimal security group for testing"
    ingress_rules = [
      {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
        security_groups = []
      }
    ]
    egress_rules = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
  }

  assert {
    condition     = aws_security_group.security_group.name == "minimal-sg"
    error_message = "Minimal security group should have correct name"
  }

  assert {
    condition     = length(aws_security_group.security_group.ingress) == 1
    error_message = "Minimal security group should have exactly 1 ingress rule"
  }

  assert {
    condition     = length(aws_security_group.security_group.egress) == 1
    error_message = "Minimal security group should have exactly 1 egress rule"
  }
}

run "database_security_group" {
  variables {
    name = "anysource-db-sg"
    description = "Database security group"
    ingress_rules = [
      {
        from_port       = 5432
        to_port         = 5432
        protocol        = "tcp"
        cidr_blocks     = ["10.0.0.0/16"]
        security_groups = ["sg-app-server"]
      },
      {
        from_port       = 3306
        to_port         = 3306
        protocol        = "tcp"
        cidr_blocks     = ["10.0.2.0/24"]
        security_groups = []
      }
    ]
    egress_rules = [
      {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
  }

  assert {
    condition     = aws_security_group.security_group.name == "anysource-db-sg"
    error_message = "Database security group should have correct name"
  }

  assert {
    condition     = contains([for rule in aws_security_group.security_group.ingress : rule.from_port], 5432)
    error_message = "Database security group should allow PostgreSQL port 5432"
  }

  assert {
    condition     = contains([for rule in aws_security_group.security_group.ingress : rule.from_port], 3306)
    error_message = "Database security group should allow MySQL port 3306"
  }

  assert {
    condition     = anytrue([
      for rule in aws_security_group.security_group.ingress : 
      contains(rule.security_groups, "sg-app-server")
    ])
    error_message = "Database security group should reference app server security group"
  }
}

run "load_balancer_security_group" {
  variables {
    name = "anysource-alb-sg"
    description = "Application Load Balancer security group"
    vpc_id = "vpc-87654321"
    ingress_rules = [
      {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
        security_groups = []
      },
      {
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
        security_groups = []
      }
    ]
    egress_rules = [
      {
        from_port   = 8000
        to_port     = 8000
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
      }
    ]
  }

  assert {
    condition     = aws_security_group.security_group.name == "anysource-alb-sg"
    error_message = "ALB security group should have correct name"
  }

  assert {
    condition     = aws_security_group.security_group.vpc_id == "vpc-87654321"
    error_message = "ALB security group should be in different VPC"
  }

  assert {
    condition     = length(aws_security_group.security_group.ingress) == 2
    error_message = "ALB security group should have 2 ingress rules for HTTP and HTTPS"
  }

  assert {
    condition     = contains([for rule in aws_security_group.security_group.egress : rule.from_port], 8000)
    error_message = "ALB security group should allow egress to application port 8000"
  }
}

run "no_ingress_rules" {
  variables {
    name = "egress-only-sg"
    description = "Security group with no ingress rules"
    ingress_rules = []
    egress_rules = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
  }

  assert {
    condition     = aws_security_group.security_group.name == "egress-only-sg"
    error_message = "Egress-only security group should have correct name"
  }

  assert {
    condition     = aws_security_group.security_group.description == "Security group with no ingress rules"
    error_message = "Egress-only security group should have correct description"
  }

  assert {
    condition     = length(aws_security_group.security_group.egress) >= 1
    error_message = "Security group should have at least 1 egress rule"
  }
}