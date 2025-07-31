mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Principal\":{\"Service\":\"ecs-tasks.amazonaws.com\"}}]}"
    }
  }
  
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/test-role"
    }
  }
  
  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/test-policy"
    }
  }
  
  mock_resource "aws_iam_role_policy_attachment" {
    defaults = {
      policy_arn = "arn:aws:iam::123456789012:policy/test-policy"
    }
  }
}

variables {
  project = "anysource"
  environment = "production"
}

run "iam_role_creation" {
  assert {
    condition     = aws_iam_role.ecs_task_execution_role.name == "anysource-ecs-task-execution-role-production"
    error_message = "ECS task execution role should have correct naming convention"
  }

  assert {
    condition     = aws_iam_role.ecs_task_execution_role.assume_role_policy == data.aws_iam_policy_document.assume_role_policy.json
    error_message = "ECS task execution role should use the correct assume role policy"
  }
}

run "iam_policy_attachments" {
  assert {
    condition     = aws_iam_role_policy_attachment.ecs_task_execution_role_policy.role == "anysource-ecs-task-execution-role-production"
    error_message = "ECS task execution role policy should be attached to correct role"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.ecs_task_execution_role_policy.policy_arn == "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
    error_message = "Should attach Amazon ECS Task Execution Role Policy"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.ecs_task_execution_role_cloudwatch_full_access.role == "anysource-ecs-task-execution-role-production"
    error_message = "CloudWatch full access policy should be attached to correct role"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.ecs_task_execution_role_cloudwatch_full_access.policy_arn == "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
    error_message = "Should attach CloudWatch Logs Full Access Policy"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.secrets_manager_access.role == "anysource-ecs-task-execution-role-production"
    error_message = "Secrets Manager access policy should be attached to correct role"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.secrets_manager_access.policy_arn == aws_iam_policy.secrets_manager_access.arn
    error_message = "Should attach custom Secrets Manager access policy"
  }
}

run "custom_secrets_manager_policy" {
  assert {
    condition     = aws_iam_policy.secrets_manager_access.name == "anysource-secrets-manager-access-production"
    error_message = "Secrets Manager policy should have correct naming convention"
  }

  assert {
    condition     = aws_iam_policy.secrets_manager_access.description == "Custom policy for Secrets Manager access for ECS tasks"
    error_message = "Secrets Manager policy should have correct description"
  }

  assert {
    condition     = can(regex("secretsmanager:GetSecretValue", aws_iam_policy.secrets_manager_access.policy))
    error_message = "Secrets Manager policy should include GetSecretValue permission"
  }

  assert {
    condition     = can(regex("secretsmanager:DescribeSecret", aws_iam_policy.secrets_manager_access.policy))
    error_message = "Secrets Manager policy should include DescribeSecret permission"
  }

  assert {
    condition     = can(regex("arn:aws:secretsmanager:\\*:\\*:secret:anysource-\\*", aws_iam_policy.secrets_manager_access.policy))
    error_message = "Secrets Manager policy should restrict access to project-specific secrets"
  }
}

run "assume_role_policy_document" {
  assert {
    condition     = can(regex("sts:AssumeRole", data.aws_iam_policy_document.assume_role_policy.json))
    error_message = "Assume role policy should allow AssumeRole action"
  }

  assert {
    condition     = can(regex("ecs-tasks.amazonaws.com", data.aws_iam_policy_document.assume_role_policy.json))
    error_message = "Assume role policy should allow ECS tasks service as principal"
  }

  assert {
    condition     = can(regex("Service", data.aws_iam_policy_document.assume_role_policy.json))
    error_message = "Assume role policy should have Service principal type"
  }
}

run "module_outputs" {
  assert {
    condition     = output.ecs_task_execution_role_arn == aws_iam_role.ecs_task_execution_role.arn
    error_message = "Output should return the correct ECS task execution role ARN"
  }
}
