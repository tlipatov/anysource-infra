mock_provider "aws" {
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
  role_names = ["backend", "frontend", "worker"]
  account = "123456789012"
  region = "us-east-1"
  suffix_secret_hash = "xyz"
}

run "iam_roles_creation" {
  assert {
    condition     = length(aws_iam_role.role) == 3
    error_message = "Should create IAM roles for all specified role names"
  }

  assert {
    condition     = aws_iam_role.role["backend"].name == "anysource-production-backend"
    error_message = "Backend IAM role should have correct naming convention"
  }

  assert {
    condition     = aws_iam_role.role["frontend"].name == "anysource-production-frontend"
    error_message = "Frontend IAM role should have correct naming convention"
  }

  assert {
    condition     = aws_iam_role.role["worker"].name == "anysource-production-worker"
    error_message = "Worker IAM role should have correct naming convention"
  }
}

run "iam_assume_role_policy" {
  assert {
    condition     = can(regex("sts:AssumeRole", aws_iam_role.role["backend"].assume_role_policy))
    error_message = "IAM role should allow AssumeRole action"
  }

  assert {
    condition     = can(regex("ecs-tasks.amazonaws.com", aws_iam_role.role["backend"].assume_role_policy))
    error_message = "IAM role should allow ECS tasks service as principal"
  }

  assert {
    condition     = can(regex("2012-10-17", aws_iam_role.role["backend"].assume_role_policy))
    error_message = "IAM role should use correct policy version"
  }

  assert {
    condition     = can(regex("Allow", aws_iam_role.role["backend"].assume_role_policy))
    error_message = "IAM role should have Allow effect"
  }
}

run "iam_policies_creation" {
  assert {
    condition     = length(aws_iam_policy.policy) == 3
    error_message = "Should create IAM policies for all specified role names"
  }

  assert {
    condition     = aws_iam_policy.policy["backend"].name == "anysource-production-backend-policy"
    error_message = "Backend IAM policy should have correct naming convention"
  }

  assert {
    condition     = aws_iam_policy.policy["frontend"].name == "anysource-production-frontend-policy"
    error_message = "Frontend IAM policy should have correct naming convention"
  }

  assert {
    condition     = aws_iam_policy.policy["worker"].name == "anysource-production-worker-policy"
    error_message = "Worker IAM policy should have correct naming convention"
  }

  assert {
    condition     = aws_iam_policy.policy["backend"].description == "Least privilege policy for anysource-production-backend"
    error_message = "Backend IAM policy should have correct description"
  }
}

run "iam_policy_secrets_manager_permissions" {
  assert {
    condition     = can(regex("secretsmanager:GetSecretValue", aws_iam_policy.policy["backend"].policy))
    error_message = "IAM policy should include Secrets Manager GetSecretValue permission"
  }

  assert {
    condition     = can(regex("arn:aws:secretsmanager:us-east-1:123456789012:secret:anysource-prod\\*", aws_iam_policy.policy["backend"].policy))
    error_message = "IAM policy should restrict Secrets Manager access to project-specific secrets with prod environment"
  }
}

run "iam_policy_s3_permissions" {
  assert {
    condition     = can(regex("s3:GetObject", aws_iam_policy.policy["backend"].policy))
    error_message = "IAM policy should include S3 GetObject permission"
  }

  assert {
    condition     = can(regex("s3:PutObject", aws_iam_policy.policy["backend"].policy))
    error_message = "IAM policy should include S3 PutObject permission"
  }

  assert {
    condition     = can(regex("s3:DeleteObject", aws_iam_policy.policy["backend"].policy))
    error_message = "IAM policy should include S3 DeleteObject permission"
  }

  assert {
    condition     = can(regex("s3:ListBucket", aws_iam_policy.policy["backend"].policy))
    error_message = "IAM policy should include S3 ListBucket permission"
  }

  assert {
    condition     = can(regex("s3:GetBucketLocation", aws_iam_policy.policy["backend"].policy))
    error_message = "IAM policy should include S3 GetBucketLocation permission"
  }

  assert {
    condition     = can(regex("arn:aws:s3:::anysource-production-\\*", aws_iam_policy.policy["backend"].policy))
    error_message = "IAM policy should restrict S3 access to project-specific buckets"
  }
}

run "iam_policy_cloudwatch_logs_permissions" {
  assert {
    condition     = can(regex("logs:CreateLogGroup", aws_iam_policy.policy["backend"].policy))
    error_message = "IAM policy should include CloudWatch Logs CreateLogGroup permission"
  }

  assert {
    condition     = can(regex("logs:CreateLogStream", aws_iam_policy.policy["backend"].policy))
    error_message = "IAM policy should include CloudWatch Logs CreateLogStream permission"
  }

  assert {
    condition     = can(regex("logs:PutLogEvents", aws_iam_policy.policy["backend"].policy))
    error_message = "IAM policy should include CloudWatch Logs PutLogEvents permission"
  }

  assert {
    condition     = can(regex("arn:aws:logs:us-east-1:123456789012:log-group:\\*-logs-production:\\*", aws_iam_policy.policy["backend"].policy))
    error_message = "IAM policy should restrict CloudWatch Logs access to environment-specific log groups"
  }
}

run "iam_policy_attachments" {
  assert {
    condition     = length(aws_iam_role_policy_attachment.policy_attachment) == 3
    error_message = "Should create policy attachments for all roles"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.policy_attachment["backend"].role == "anysource-production-backend"
    error_message = "Backend policy attachment should reference correct role"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.policy_attachment["frontend"].role == "anysource-production-frontend"
    error_message = "Frontend policy attachment should reference correct role"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.policy_attachment["worker"].role == "anysource-production-worker"
    error_message = "Worker policy attachment should reference correct role"
  }
}

run "environment_local_transformation" {
  assert {
    condition     = can(regex("anysource-prod\\*", aws_iam_policy.policy["backend"].policy))
    error_message = "Production environment should be transformed to 'prod' in secrets manager resource ARN"
  }
}

run "staging_environment" {
  variables {
    environment = "stg"
  }

  assert {
    condition     = aws_iam_role.role["backend"].name == "anysource-stg-backend"
    error_message = "Staging IAM role should use 'stg' environment in name"
  }

  assert {
    condition     = aws_iam_policy.policy["backend"].name == "anysource-stg-backend-policy"
    error_message = "Staging IAM policy should use 'stg' environment in name"
  }

  assert {
    condition     = can(regex("anysource-stg\\*", aws_iam_policy.policy["backend"].policy))
    error_message = "Staging environment should use 'stg' in secrets manager resource ARN"
  }

  assert {
    condition     = can(regex("arn:aws:s3:::anysource-stg-\\*", aws_iam_policy.policy["backend"].policy))
    error_message = "Staging environment should use 'stg' in S3 resource ARN"
  }

  assert {
    condition     = can(regex("\\*-logs-stg:\\*", aws_iam_policy.policy["backend"].policy))
    error_message = "Staging environment should use 'stg' in CloudWatch logs resource ARN"
  }
}

run "single_role" {
  variables {
    role_names = ["api"]
  }

  assert {
    condition     = length(aws_iam_role.role) == 1
    error_message = "Should create exactly one IAM role"
  }

  assert {
    condition     = aws_iam_role.role["api"].name == "anysource-production-api"
    error_message = "Single IAM role should have correct naming"
  }

  assert {
    condition     = length(aws_iam_policy.policy) == 1
    error_message = "Should create exactly one IAM policy"
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.policy_attachment) == 1
    error_message = "Should create exactly one policy attachment"
  }
}

run "different_project_and_account" {
  variables {
    project = "testproject"
    account = "987654321098"
    region = "us-west-2"
  }

  assert {
    condition     = aws_iam_role.role["backend"].name == "testproject-production-backend"
    error_message = "IAM role should use different project name"
  }

  assert {
    condition     = aws_iam_policy.policy["backend"].name == "testproject-production-backend-policy"
    error_message = "IAM policy should use different project name"
  }

  assert {
    condition     = can(regex("arn:aws:secretsmanager:us-west-2:987654321098:secret:testproject-prod\\*", aws_iam_policy.policy["backend"].policy))
    error_message = "IAM policy should use different account, region, and project in Secrets Manager ARN"
  }

  assert {
    condition     = can(regex("arn:aws:s3:::testproject-production-\\*", aws_iam_policy.policy["backend"].policy))
    error_message = "IAM policy should use different project in S3 ARN"
  }

  assert {
    condition     = can(regex("arn:aws:logs:us-west-2:987654321098:log-group:", aws_iam_policy.policy["backend"].policy))
    error_message = "IAM policy should use different account and region in CloudWatch logs ARN"
  }
}