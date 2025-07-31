mock_provider "aws" {}

run "ecr_single_repository" {
  variables {
    project = "anysource"
    environment = "production"
    ecr_repositories = ["api"]
  }

  assert {
    condition     = length(aws_ecr_repository.ecr_repository) == 1
    error_message = "Should create exactly 1 ECR repository"
  }

  assert {
    condition     = aws_ecr_repository.ecr_repository["api"].name == "api-production"
    error_message = "Repository name should include environment suffix"
  }

  assert {
    condition     = aws_ecr_repository.ecr_repository["api"].image_tag_mutability == "MUTABLE"
    error_message = "Repository should allow mutable image tags"
  }

  assert {
    condition     = aws_ecr_repository.ecr_repository["api"].force_delete == true
    error_message = "Repository should have force delete enabled"
  }

  assert {
    condition     = aws_ecr_repository.ecr_repository["api"].image_scanning_configuration[0].scan_on_push == true
    error_message = "Repository should have scan on push enabled"
  }
}

run "ecr_multiple_repositories" {
  variables {
    project = "anysource"
    environment = "production"
    ecr_repositories = ["api", "web", "worker"]
  }

  assert {
    condition     = length(aws_ecr_repository.ecr_repository) == 3
    error_message = "Should create exactly 3 ECR repositories"
  }

  assert {
    condition     = aws_ecr_repository.ecr_repository["api"].name == "api-production"
    error_message = "API repository name should include production environment"
  }

  assert {
    condition     = aws_ecr_repository.ecr_repository["web"].name == "web-production"
    error_message = "Web repository name should include production environment"
  }

  assert {
    condition     = aws_ecr_repository.ecr_repository["worker"].name == "worker-production"
    error_message = "Worker repository name should include production environment"
  }
}

run "ecr_repository_policies" {
  variables {
    project = "anysource"
    environment = "production"
    ecr_repositories = ["api", "web", "worker"]
  }

  assert {
    condition     = length(aws_ecr_repository_policy.ecr_repository_policy) == 3
    error_message = "Should create repository policies for all repositories"
  }

  assert {
    condition     = aws_ecr_repository_policy.ecr_repository_policy["api"].repository == "api-production"
    error_message = "API repository policy should reference correct repository name"
  }

  assert {
    condition     = aws_ecr_repository_policy.ecr_repository_policy["web"].repository == "web-production"
    error_message = "Web repository policy should reference correct repository name"
  }

  assert {
    condition     = aws_ecr_repository_policy.ecr_repository_policy["worker"].repository == "worker-production"
    error_message = "Web repository policy should reference correct repository name"
  }
}

run "ecr_lifecycle_policies" {
  variables {
    project = "anysource"
    environment = "stg"
    ecr_repositories = ["api", "web"]
  }

  assert {
    condition     = length(aws_ecr_lifecycle_policy.lifecycle_policy) == 2
    error_message = "Should create lifecycle policies for all repositories"
  }

  assert {
    condition     = aws_ecr_lifecycle_policy.lifecycle_policy["api"].repository == "api-stg" 
    error_message = "API lifecycle policy should reference correct repository name"
  }

  assert {
    condition     = aws_ecr_lifecycle_policy.lifecycle_policy["web"].repository == "web-stg"
    error_message = "Web lifecycle policy should reference correct repository name"
  }

  assert {
    condition     = can(regex("Keep last 10 images", aws_ecr_lifecycle_policy.lifecycle_policy["api"].policy))
    error_message = "Lifecycle policy should contain image retention rule"
  }

  assert {
    condition     = can(regex("imageCountMoreThan", aws_ecr_lifecycle_policy.lifecycle_policy["api"].policy))
    error_message = "Lifecycle policy should use count-based expiration"
  }
}

run "ecr_outputs_single_repository" {
  variables {
    project = "anysource"
    environment = "stg"
    ecr_repositories = ["api"]
  }

  assert {
    condition     = length(output.ecr_repositories) == 1
    error_message = "Should output exactly 1 repository URL"
  }

  assert {
    condition     = output.ecr_repository_urls["api"] == aws_ecr_repository.ecr_repository["api"].repository_url
    error_message = "Repository URL output should match resource URL"
  }

  assert {
    condition     = output.ecr_repository_names["api"] == aws_ecr_repository.ecr_repository["api"].name
    error_message = "Repository name output should match resource name"
  }

  assert {
    condition     = output.ecr_repository_names["api"] == "api-stg"
    error_message = "Repository name should include environment suffix"
  }
}

run "ecr_outputs_multiple_repositories" {
  variables {
    project = "anysource"
    environment = "production"
    ecr_repositories = ["api", "web", "worker"]
  }

  assert {
    condition     = length(output.ecr_repositories) == 3
    error_message = "Should output exactly 3 repository URLs"
  }

  assert {
    condition     = length(output.ecr_repository_urls) == 3
    error_message = "Should output URLs for all 3 repositories"
  }

  assert {
    condition     = length(output.ecr_repository_names) == 3
    error_message = "Should output names for all 3 repositories"
  }

  assert {
    condition     = output.ecr_repository_names["api"] == "api-production"
    error_message = "API repository name should include production environment"
  }

  assert {
    condition     = output.ecr_repository_names["web"] == "web-production"
    error_message = "Web repository name should include production environment"
  }

  assert {
    condition     = output.ecr_repository_names["worker"] == "worker-production"
    error_message = "Worker repository name should include production environment"
  }
}

run "ecr_environment_validation" {
  variables {
    project = "anysource"
    environment = "prod"
    ecr_repositories = ["api"]
  }

  assert {
    condition     = aws_ecr_repository.ecr_repository["api"].name == "api-prod"
    error_message = "Repository should use 'prod' environment in name"
  }
}