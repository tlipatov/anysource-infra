mock_provider "aws" {}

run "s3_sets_correct_name" {
  variables {
    project = "anysource"
    environment = "production"
    name = "unittest"
    acl = "private"
  }

  assert {
    condition     = aws_s3_bucket.s3_buckets.bucket == "anysource-production-unittest"
    error_message = "incorrect bucket name"
  }
}
