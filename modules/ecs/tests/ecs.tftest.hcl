mock_provider "aws" {}

variables {
  project = "anysource"
  environment = "production"
  region = "us-east-1"
  vpc_id = "vpc-12345678"
  vpc_cidr = "10.0.0.0/16"
  private_subnets = ["subnet-private-1", "subnet-private-2"]
  public_subnets = ["subnet-public-1", "subnet-public-2"]
  services_names = ["backend", "frontend"]
  ecs_task_execution_role_arn = "arn:aws:iam::123456789012:role/ecsTaskExecutionRole"
  prestart_container_cpu = 256
  prestart_container_memory = 512
  ecr_repositories = {
    backend = "123456789012.dkr.ecr.us-east-1.amazonaws.com/backend:latest"
    frontend = "123456789012.dkr.ecr.us-east-1.amazonaws.com/frontend:latest"
  }
  services_configurations = {
    backend = {
      cpu = 1024
      memory = 2048
      container_port = 8000
      host_port = 8000
      desired_count = 2
      max_capacity = 10
      memory_auto_scalling_target_value = 80
      cpu_auto_scalling_target_value = 70
      environment = [
        {
          name = "API_URL"
          value = "http://localhost:8000"
        }
      ]
    }
    frontend = {
      cpu = 512
      memory = 1024
      container_port = 3000
      host_port = 3000
      desired_count = 1
      max_capacity = 5
      memory_auto_scalling_target_value = 80
      cpu_auto_scalling_target_value = 70
      environment = []
    }
  }
  public_alb_target_groups = {
    backend = {
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/backend-tg/1234567890123456"
    }
    frontend = {
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/frontend-tg/1234567890123456"
    }
  }
  public_alb_security_group = "sg-12345678"
  env_vars = {
    NODE_ENV = "staging"
    DEBUG = "true"
  }
  secret_vars = {
    DATABASE_URL = "arn:aws:secretsmanager:us-east-1:123456789012:secret:db-url-AbCdEf"
  }
}

run "aws_ecs_cluster" {
  assert {
    condition     = aws_ecs_cluster.ecs_cluster.name == "anysource-production-cluster"
    error_message = "ECS cluster name should include project and environment"
  }
}

run "aws_cloudwatch" {
  assert {
    condition     = length(aws_cloudwatch_log_group.ecs_cw_log_group) == 2
    error_message = "Should create log groups for all services"
  }

  assert {
    condition     = aws_cloudwatch_log_group.ecs_cw_log_group["backend"].name == "backend-logs-production"
    error_message = "Backend log group should have correct naming"
  }

  assert {
    condition     = aws_cloudwatch_log_group.ecs_cw_log_group["frontend"].name == "frontend-logs-production"
    error_message = "Frontend log group should have correct naming"
  }

  assert {
    condition     = aws_cloudwatch_log_group.ecs_cw_log_group["backend"].retention_in_days == 14
    error_message = "Log group should have 14 day retention"
  }

  assert {
    condition     = aws_cloudwatch_log_group.prestart_cw_log_group.name == "prestart-logs-production"
    error_message = "Prestart log group should have correct naming"
  }

  assert {
    condition     = aws_cloudwatch_log_group.prestart_cw_log_group.retention_in_days == 14
    error_message = "Prestart log group should have 14 day retention"
  }
}

run "aws_ecs_task_definition" {
  assert {
    condition     = length(aws_ecs_task_definition.ecs_task_definition) == 2
    error_message = "Should create task definitions for all services"
  }

  assert {
    condition     = aws_ecs_task_definition.ecs_task_definition["backend"].family == "anysource-backend-production"
    error_message = "Backend task definition should have correct family name"
  }

  assert {
    condition     = contains(aws_ecs_task_definition.ecs_task_definition["backend"].requires_compatibilities, "FARGATE")
    error_message = "Task definition should require FARGATE compatibility"
  }

  assert {
    condition     = aws_ecs_task_definition.ecs_task_definition["backend"].network_mode == "awsvpc"
    error_message = "Task definition should use awsvpc network mode"
  }

  assert {
    condition     = aws_ecs_task_definition.ecs_task_definition["backend"].memory == "2048"
    error_message = "Backend task definition should have correct memory allocation"
  }

  assert {
    condition     = aws_ecs_task_definition.ecs_task_definition["backend"].cpu == "1024"
    error_message = "Backend task definition should have correct CPU allocation"
  }

  assert {
    condition     = aws_ecs_task_definition.ecs_task_definition["frontend"].memory == "1024"
    error_message = "Frontend task definition should have correct memory allocation"
  }

  assert {
    condition     = aws_ecs_task_definition.ecs_task_definition["frontend"].cpu == "512"
    error_message = "Frontend task definition should have correct CPU allocation"
  }
}

run "aws_ecs_service" {
  assert {
    condition     = length(aws_ecs_service.private_service) == 2
    error_message = "Should create ECS services for all configurations"
  }

  assert {
    condition     = aws_ecs_service.private_service["backend"].name == "backend-service"
    error_message = "Backend service should have correct name"
  }

  assert {
    condition     = aws_ecs_service.private_service["backend"].launch_type == "FARGATE"
    error_message = "ECS service should use FARGATE launch type"
  }

  assert {
    condition     = aws_ecs_service.private_service["backend"].desired_count == 2
    error_message = "Backend service should have correct desired count"
  }

  assert {
    condition     = aws_ecs_service.private_service["frontend"].desired_count == 1
    error_message = "Frontend service should have correct desired count"
  }

  assert {
    condition     = length(aws_ecs_service.private_service["backend"].network_configuration[0].subnets) == 2
    error_message = "Backend service should be configured with private subnets"
  }

  assert {
    condition     = aws_appautoscaling_target.service_autoscaling["backend"].max_capacity == 10
    error_message = "Autoscaling target should have correct max capacity"
  }

  assert {
    condition     = aws_appautoscaling_target.service_autoscaling["backend"].min_capacity == 2
    error_message = "Autoscaling target should have min capacity equal to desired count"
  }

  assert {
    condition     = aws_appautoscaling_target.service_autoscaling["backend"].scalable_dimension == "ecs:service:DesiredCount"
    error_message = "Autoscaling target should scale desired count"
  }

  assert {
    condition     = aws_appautoscaling_policy.ecs_policy_memory["backend"].name == "anysource-memory-autoscaling"
    error_message = "Memory autoscaling policy should have correct name"
  }

  assert {
    condition     = aws_appautoscaling_policy.ecs_policy_cpu["backend"].name == "anysource-cpu-autoscaling"
    error_message = "CPU autoscaling policy should have correct name"
  }

  assert {
    condition     = aws_appautoscaling_policy.ecs_policy_memory["backend"].target_tracking_scaling_policy_configuration[0].target_value == 80
    error_message = "Memory autoscaling policy should have correct target value"
  }

  assert {
    condition     = aws_appautoscaling_policy.ecs_policy_cpu["backend"].target_tracking_scaling_policy_configuration[0].target_value == 70
    error_message = "CPU autoscaling policy should have correct target value"
  }
}
