mock_provider "aws" {
  mock_data "aws_secretsmanager_secret" {
    defaults = {
      id = "arn:aws:secretsmanager:us-east-1:123456789012:secret:db-password-AbCdEf"
    }
  }
  
  mock_data "aws_secretsmanager_secret_version" {
    defaults = {
      secret_string = "{\"PLATFORM_DB_PASSWORD\":\"test-password-123\"}"
    }
  }
  
  mock_resource "aws_rds_cluster" {
    defaults = {
      endpoint = "aurora-anysource-prod-cluster.cluster-xyz.us-east-1.rds.amazonaws.com"
      reader_endpoint = "aurora-anysource-prod-cluster.cluster-ro-xyz.us-east-1.rds.amazonaws.com"
    }
  }
  
  mock_resource "aws_security_group" {
    defaults = {
      id = "sg-12345678"
    }
  }
  
  mock_resource "aws_db_subnet_group" {
    defaults = {
      name = "aurora-anysource-prod-subnet-group"
    }
  }
}

variables {
  project = "anysource"
  environment = "production"
  name = "unittest"
  engine_version = "15.4"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  min_capacity = "0.5"
  max_capacity = "16"
  publicly_accessible = false
  subnet_ids = ["subnet-12345", "subnet-67890", "subnet-abcde"]
  vpc_id = "vpc-12345678"
  vpc_cidr = "10.0.0.0/16"
  count_replicas = 2
  deletion_protection = true
  db_username = "anysource_user"
  db_password_secret_name = "anysource-prod-db-password"
}

run "rds_cluster_configuration" {
  assert {
    condition     = aws_rds_cluster.rds_cluster.cluster_identifier == "aurora-anysource-prod-cluster"
    error_message = "RDS cluster identifier should use correct naming convention"
  }

  assert {
    condition     = aws_rds_cluster.rds_cluster.engine == "aurora-postgresql"
    error_message = "RDS cluster should use Aurora PostgreSQL engine"
  }

  assert {
    condition     = aws_rds_cluster.rds_cluster.engine_mode == "provisioned"
    error_message = "RDS cluster should use provisioned engine mode"
  }

  assert {
    condition     = aws_rds_cluster.rds_cluster.engine_version == "15.4"
    error_message = "RDS cluster should use specified engine version"
  }

  assert {
    condition     = aws_rds_cluster.rds_cluster.database_name == "unittest"
    error_message = "RDS cluster should have correct database name"
  }

  assert {
    condition     = aws_rds_cluster.rds_cluster.master_username == "anysource_user"
    error_message = "RDS cluster should have correct master username"
  }

  assert {
    condition     = aws_rds_cluster.rds_cluster.storage_encrypted == true
    error_message = "RDS cluster should have encryption enabled"
  }

  assert {
    condition     = aws_rds_cluster.rds_cluster.skip_final_snapshot == true
    error_message = "RDS cluster should skip final snapshot for testing"
  }

  assert {
    condition     = aws_rds_cluster.rds_cluster.deletion_protection == true
    error_message = "RDS cluster should have deletion protection enabled"
  }

  assert {
    condition     = aws_rds_cluster.rds_cluster.backup_retention_period == 10
    error_message = "RDS cluster should have 10-day backup retention"
  }
}

run "rds_serverlessv2_scaling" {
  assert {
    condition     = aws_rds_cluster.rds_cluster.serverlessv2_scaling_configuration[0].min_capacity == 0.5
    error_message = "RDS cluster should have correct min capacity"
  }

  assert {
    condition     = aws_rds_cluster.rds_cluster.serverlessv2_scaling_configuration[0].max_capacity == 16
    error_message = "RDS cluster should have correct max capacity"
  }
}

run "rds_performance_insights" {
  assert {
    condition     = aws_rds_cluster.rds_cluster.performance_insights_enabled == true
    error_message = "RDS cluster should have Performance Insights enabled"
  }

  assert {
    condition     = aws_rds_cluster.rds_cluster.performance_insights_retention_period == 7
    error_message = "RDS cluster should have 7-day Performance Insights retention"
  }

  assert {
    condition     = contains(aws_rds_cluster.rds_cluster.enabled_cloudwatch_logs_exports, "postgresql")
    error_message = "RDS cluster should export PostgreSQL logs to CloudWatch"
  }
}

run "rds_http_endpoint_prod" {

  assert {
    condition     = aws_rds_cluster.rds_cluster.cluster_identifier == "aurora-anysource-prod-cluster"
    error_message = "RDS cluster identifier should use prod environment"
  }

  assert {
    condition     = aws_rds_cluster.rds_cluster.enable_http_endpoint == false
    error_message = "RDS cluster should have HTTP endpoint disabled in prod"
  }
}

run "rds_http_endpoint_staging" {
  variables {
    environment = "stg"
  }

  assert {
    condition     = aws_rds_cluster.rds_cluster.cluster_identifier == "aurora-anysource-stg-cluster"
    error_message = "RDS cluster identifier should use staging environment"
  }

  assert {
    condition     = aws_rds_cluster.rds_cluster.enable_http_endpoint == true
    error_message = "RDS cluster should have HTTP endpoint enabled in staging"
  }
}

run "rds_eu_environment" {
  variables {
    environment = "eu"
  }

  assert {
    condition     = aws_rds_cluster.rds_cluster.cluster_identifier == "aurora-anysource-eu-cluster"
    error_message = "RDS cluster identifier should use EU environment"
  }

  assert {
    condition     = aws_rds_cluster.rds_cluster.enable_http_endpoint == true
    error_message = "RDS cluster should have HTTP endpoint enabled in EU"
  }
}

run "rds_subnet_group" {
  assert {
    condition     = aws_db_subnet_group.subnet_group.name == "aurora-anysource-prod-subnet-group"
    error_message = "DB subnet group should have correct naming convention"
  }

  assert {
    condition     = length(aws_db_subnet_group.subnet_group.subnet_ids) == 3
    error_message = "DB subnet group should contain all specified subnets"
  }

  assert {
    condition     = contains(aws_db_subnet_group.subnet_group.subnet_ids, "subnet-12345")
    error_message = "DB subnet group should contain first subnet"
  }

  assert {
    condition     = aws_db_subnet_group.subnet_group.tags.Name == "aurora-anysource-prod-subnet-group"
    error_message = "DB subnet group should have correct Name tag"
  }
}

run "rds_cluster_instances" {
  assert {
    condition     = length(aws_rds_cluster_instance.rds_cluster_instance) == 2
    error_message = "Should create correct number of RDS cluster instances"
  }

  assert {
    condition     = aws_rds_cluster_instance.rds_cluster_instance[0].identifier == "anysource-prod-1"
    error_message = "First RDS instance should have correct identifier"
  }

  assert {
    condition     = aws_rds_cluster_instance.rds_cluster_instance[1].identifier == "anysource-prod-2"
    error_message = "Second RDS instance should have correct identifier"
  }

  assert {
    condition     = aws_rds_cluster_instance.rds_cluster_instance[0].instance_class == "db.serverless"
    error_message = "RDS instances should use serverless instance class"
  }

  assert {
    condition     = aws_rds_cluster_instance.rds_cluster_instance[0].publicly_accessible == false
    error_message = "RDS instances should not be publicly accessible"
  }
}

run "rds_security_group" {
  assert {
    condition     = aws_security_group.rds_security_group.name == "aurora-anysource-prod-sg"
    error_message = "RDS security group should have correct naming convention"
  }

  assert {
    condition     = aws_security_group.rds_security_group.description == "Security group for RDS cluster"
    error_message = "RDS security group should have correct description"
  }

  assert {
    condition     = aws_security_group.rds_security_group.vpc_id == "vpc-12345678"
    error_message = "RDS security group should be in correct VPC"
  }

  assert {
    condition     = length(aws_security_group.rds_security_group.ingress) == 1
    error_message = "RDS security group should have exactly one ingress rule"
  }

  assert {
    condition     = contains([for rule in aws_security_group.rds_security_group.ingress : rule.from_port], 5432)
    error_message = "RDS security group should allow PostgreSQL port 5432"
  }

  assert {
    condition     = contains([for rule in aws_security_group.rds_security_group.ingress : rule.to_port], 5432)
    error_message = "RDS security group should allow PostgreSQL port 5432"
  }

  assert {
    condition     = contains([for rule in aws_security_group.rds_security_group.ingress : rule.protocol], "tcp")
    error_message = "RDS security group should use TCP protocol"
  }

  assert {
    condition     = aws_security_group.rds_security_group.tags.Name == "aurora-anysource-prod-sg"
    error_message = "RDS security group should have correct Name tag"
  }
}

run "module_outputs" {
  assert {
    condition     = output.cluster_endpoint == aws_rds_cluster.rds_cluster.endpoint
    error_message = "Cluster endpoint output should match resource"
  }

  assert {
    condition     = output.cluster_reader_endpoint == aws_rds_cluster.rds_cluster.reader_endpoint
    error_message = "Cluster reader endpoint output should match resource"
  }

  assert {
    condition     = output.cluster_identifier == aws_rds_cluster.rds_cluster.cluster_identifier
    error_message = "Cluster identifier output should match resource"
  }

  assert {
    condition     = output.database_name == aws_rds_cluster.rds_cluster.database_name
    error_message = "Database name output should match resource"
  }
}

run "custom_replica_count" {
  variables {
    count_replicas = 3
  }

  assert {
    condition     = length(aws_rds_cluster_instance.rds_cluster_instance) == 3
    error_message = "Should create custom number of RDS cluster instances"
  }

  assert {
    condition     = aws_rds_cluster_instance.rds_cluster_instance[2].identifier == "anysource-prod-3"
    error_message = "Third RDS instance should have correct identifier"
  }
}

run "publicly_accessible_database" {
  variables {
    publicly_accessible = true
  }

  assert {
    condition     = aws_rds_cluster_instance.rds_cluster_instance[0].publicly_accessible == true
    error_message = "RDS instances should be publicly accessible when configured"
  }
}