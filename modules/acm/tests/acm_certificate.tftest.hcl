mock_provider "aws" {}

run "acm_certificate_stg_configuration" {
  variables {
    domain_name = "stg.example.com"
    environment = "stg"
  }

  assert {
    condition     = aws_acm_certificate.certificate.domain_name == "stg.example.com"
    error_message = "ACM certificate domain name should match the input variable"
  }

  assert {
    condition     = aws_acm_certificate.certificate.validation_method == "DNS"
    error_message = "ACM certificate should use DNS validation method"
  }

  assert {
    condition     = aws_acm_certificate.certificate.tags.Environment == "stg"
    error_message = "ACM certificate should have the correct environment tag"
  }
}

run "acm_certificate_production_environment" {
  variables {
    domain_name = "prod.example.com"
    environment = "production"
  }

  assert {
    condition     = aws_acm_certificate.certificate.domain_name == "prod.example.com"
    error_message = "ACM certificate domain name should match production domain"
  }

  assert {
    condition     = aws_acm_certificate.certificate.tags.Environment == "production"
    error_message = "ACM certificate should have production environment tag"
  }
}

run "acm_certificate_has_required_attributes" {
  variables {
    domain_name = "stg.example.com"
    environment = "stg"
  }

  assert {
    condition     = aws_acm_certificate.certificate.arn != ""
    error_message = "ACM certificate should have a non-empty ARN"
  }

  assert {
    condition     = aws_acm_certificate.certificate.status != ""
    error_message = "ACM certificate should have a status"
  }
}

run "acm_certificate_outputs" {
  variables {
    domain_name = "prod.example.com"
    environment = "prod"
  }

  assert {
    condition     = output.certificate_arn == aws_acm_certificate.certificate.arn
    error_message = "Certificate ARN output should match the resource ARN"
  }
}

run "acm_certificate_wildcard_domain" {
  variables {
    domain_name = "*.wildcard.example.com"
    environment = "stg"
  }

  assert {
    condition     = aws_acm_certificate.certificate.domain_name == "*.wildcard.example.com"
    error_message = "ACM certificate should support wildcard domains"
  }

  assert {
    condition     = aws_acm_certificate.certificate.validation_method == "DNS"
    error_message = "Wildcard certificate should still use DNS validation"
  }
}
