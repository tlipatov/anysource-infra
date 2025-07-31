mock_provider "aws" {
  mock_resource "aws_lb" {
    defaults = {
      arn        = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/test-alb/1234567890123456"
      id         = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/test-alb/1234567890123456"
      dns_name   = "test-alb-123456789.us-east-1.elb.amazonaws.com"
      zone_id    = "Z35SXDOTRQ7X7K"
      arn_suffix = "app/test-alb/1234567890123456"
    }
  }
  
  mock_resource "aws_lb_listener" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/test-alb/1234567890123456/1234567890123456"
    }
  }
  
  mock_resource "aws_lb_target_group" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test-tg/1234567890123456"
    }
  }
  
  mock_resource "aws_lb_listener_rule" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener-rule/app/test-alb/1234567890123456/1234567890123456/1234567890123456"
    }
  }
}

run "alb_external" {
  variables {
    name                = "alb-external"
    environment         = "production"
    internal            = false
    vpc_id              = "vpc-12345678"
    load_balancer_type  = "application"
    subnets             = ["subnet-12345", "subnet-67890"]
    security_groups     = ["sg-12345"]
    enable_https        = false
    target_groups = {
      api = {
        path_pattern      = ["/api/*"]
        health_check_path = "/health"
        protocol          = "HTTP"
        port              = 3000
      }
    }
  }

  assert {
    condition     = aws_lb.alb.name == "alb-external"
    error_message = "ALB name should match the input variable"
  }

  assert {
    condition     = aws_lb.alb.internal == false
    error_message = "ALB should be external (not internal)"
  }

  assert {
    condition     = aws_lb.alb.load_balancer_type == "application"
    error_message = "ALB should be application type"
  }

  assert {
    condition     = aws_lb.alb.idle_timeout == 120
    error_message = "ALB idle timeout should be 120 seconds"
  }

  assert {
    condition     = aws_lb.alb.drop_invalid_header_fields == true
    error_message = "ALB should drop invalid header fields"
  }

  assert {
    condition     = length(aws_lb.alb.subnets) == 2
    error_message = "ALB should have 2 subnets configured"
  }

  assert {
    condition     = contains(aws_lb.alb.subnets, "subnet-12345")
    error_message = "ALB should contain the first subnet"
  }

  assert {
    condition     = contains(aws_lb.alb.subnets, "subnet-67890")
    error_message = "ALB should contain the second subnet"
  }

  assert {
    condition     = length(aws_lb.alb.security_groups) == 1
    error_message = "ALB should have 1 security group configured"
  }

  assert {
    condition     = contains(aws_lb.alb.security_groups, "sg-12345")
    error_message = "ALB should contain the specified security group"
  }
}

run "alb_internal" {
  variables {
    name                = "alb-internal"
    environment         = "production"
    internal            = true
    vpc_id              = "vpc-12345678"
    load_balancer_type  = "application"
    subnets             = ["subnet-12345", "subnet-67890"]
    security_groups     = ["sg-12345"]
    enable_https        = false
    target_groups = {
      api = {
        path_pattern      = ["/api/*"]
        health_check_path = "/health"
        protocol          = "HTTP"
        port              = 3000
      }
    }
  }

  assert {
    condition     = aws_lb.alb.name == "alb-internal"
    error_message = "Internal ALB name should match input"
  }

  assert {
    condition     = aws_lb.alb.internal == true
    error_message = "ALB should be internal"
  }

  assert {
    condition     = aws_lb.alb.load_balancer_type == "application"
    error_message = "ALB should be application type"
  }

  assert {
    condition     = aws_lb.alb.idle_timeout == 120
    error_message = "ALB idle timeout should be 120 seconds"
  }

  assert {
    condition     = aws_lb.alb.drop_invalid_header_fields == true
    error_message = "ALB should drop invalid header fields"
  }

  assert {
    condition     = length(aws_lb.alb.subnets) == 2
    error_message = "ALB should have 2 subnets configured"
  }

  assert {
    condition     = contains(aws_lb.alb.subnets, "subnet-12345")
    error_message = "ALB should contain the first subnet"
  }

  assert {
    condition     = contains(aws_lb.alb.subnets, "subnet-67890")
    error_message = "ALB should contain the second subnet"
  }

  assert {
    condition     = length(aws_lb.alb.security_groups) == 1
    error_message = "ALB should have 1 security group configured"
  }

  assert {
    condition     = contains(aws_lb.alb.security_groups, "sg-12345")
    error_message = "ALB should contain the specified security group"
  }
}

run "nlb_internal" {
  variables {
    name                = "nlb-external"
    environment         = "production"
    internal            = false
    vpc_id              = "vpc-12345678"
    load_balancer_type  = "network"
    subnets             = ["subnet-12345", "subnet-67890"]
    security_groups     = ["sg-12345"]
    enable_https        = false
    target_groups = {
      api = {
        path_pattern      = ["/api/*"]
        health_check_path = "/health"
        protocol          = "HTTP"
        port              = 3000
      }
    }
  }

  assert {
    condition     = aws_lb.alb.name == "nlb-external"
    error_message = "Network load balancer name should match input"
  }

  assert {
    condition     = aws_lb.alb.internal == false
    error_message = "ALB should be external (not internal)"
  }

  assert {
    condition     = aws_lb.alb.load_balancer_type == "network"
    error_message = "Load balancer should be network type"
  }

  assert {
    condition     = length(aws_lb.alb.subnets) == 2
    error_message = "ALB should have 2 subnets configured"
  }

  assert {
    condition     = contains(aws_lb.alb.subnets, "subnet-12345")
    error_message = "ALB should contain the first subnet"
  }

  assert {
    condition     = contains(aws_lb.alb.subnets, "subnet-67890")
    error_message = "ALB should contain the second subnet"
  }

  assert {
    condition     = length(aws_lb.alb.security_groups) == 1
    error_message = "ALB should have 1 security group configured"
  }

  assert {
    condition     = contains(aws_lb.alb.security_groups, "sg-12345")
    error_message = "ALB should contain the specified security group"
  }

}

run "nlb_external" {
  variables {
    name                = "nlb-internal"
    environment         = "production"
    internal            = true
    vpc_id              = "vpc-12345678"
    load_balancer_type  = "network"
    subnets             = ["subnet-12345", "subnet-67890"]
    security_groups     = ["sg-12345"]
    enable_https        = false
    target_groups = {
      api = {
        path_pattern      = ["/api/*"]
        health_check_path = "/health"
        protocol          = "HTTP"
        port              = 3000
      }
    }
  }

  assert {
    condition     = aws_lb.alb.name == "nlb-internal"
    error_message = "Network load balancer name should match input"
  }

  assert {
    condition     = aws_lb.alb.internal == true
    error_message = "ALB should be internal"
  }

  assert {
    condition     = aws_lb.alb.load_balancer_type == "network"
    error_message = "Load balancer should be network type"
  }

  assert {
    condition     = length(aws_lb.alb.subnets) == 2
    error_message = "ALB should have 2 subnets configured"
  }

  assert {
    condition     = contains(aws_lb.alb.subnets, "subnet-12345")
    error_message = "ALB should contain the first subnet"
  }

  assert {
    condition     = contains(aws_lb.alb.subnets, "subnet-67890")
    error_message = "ALB should contain the second subnet"
  }

  assert {
    condition     = length(aws_lb.alb.security_groups) == 1
    error_message = "ALB should have 1 security group configured"
  }

  assert {
    condition     = contains(aws_lb.alb.security_groups, "sg-12345")
    error_message = "ALB should contain the specified security group"
  }

}

run "alb_outputs" {
  variables {
    name                = "test-alb"
    environment         = "stg"
    internal            = false
    vpc_id              = "vpc-12345678"
    load_balancer_type  = "application"
    subnets             = ["subnet-12345", "subnet-67890"]
    security_groups     = ["sg-12345"]
    enable_https        = false
    target_groups = {
      api = {
        path_pattern      = ["/api/*"]
        health_check_path = "/health"
        protocol          = "HTTP"
        port              = 3000
      }
    }
  }

  assert {
    condition     = output.target_groups == aws_lb_target_group.alb_target_group
    error_message = "ALB target groups output should match the resource"
  }

    assert {
    condition     = output.alb_listener == aws_lb_listener.alb_listener_http
    error_message = "ALB listener http output should match the resource"
  }

  assert {
    condition     = output.alb_arn == aws_lb.alb.arn
    error_message = "ALB ARN output should match the resource ARN"
  }

  assert {
    condition     = output.alb_dns_name == aws_lb.alb.dns_name
    error_message = "ALB DNS name output should match the resource DNS name"
  }

  assert {
    condition     = output.alb_zone_id == aws_lb.alb.zone_id
    error_message = "ALB zone ID output should match the resource zone ID"  
  }

  assert {
    condition     = output.alb_arn_suffix == aws_lb.alb.arn_suffix
    error_message = "ALB ARN suffix output should match the resource ARN suffix"
  }
}