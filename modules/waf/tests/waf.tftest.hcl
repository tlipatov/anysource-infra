mock_provider "aws" {
  mock_resource "aws_wafv2_web_acl" {
    defaults = {
      arn = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/test-web-acl/1234567890123456"
      id  = "1234567890123456"
    }
  }
}

variables {
  project = "anysource" 
  environment = "production"
  name = "web-firewall"
  cloudwatch_metrics = true
  sampled_requests = true
  metric_name = "WebACLMetrics"
  resources_arn = [
    "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/test-alb/1234567890123456",
    "arn:aws:apigateway:us-east-1::/restapis/test-api/stages/prod"
  ]
}

run "waf_web_acl_basic_configuration" {
  assert {
    condition     = aws_wafv2_web_acl.waf.name == "web-firewall-anysource-production"
    error_message = "WAF Web ACL should have correct name"
  }

  assert {
    condition     = aws_wafv2_web_acl.waf.description == "waf that for web-firewall in env production"
    error_message = "WAF Web ACL should have correct description"
  }

  assert {
    condition     = aws_wafv2_web_acl.waf.scope == "REGIONAL"
    error_message = "WAF Web ACL should have REGIONAL scope"
  }

  assert {
    condition     = aws_wafv2_web_acl.waf.default_action[0].allow != null
    error_message = "WAF Web ACL should have allow as default action"
  }
}

run "waf_visibility_configuration" {
  assert {
    condition     = aws_wafv2_web_acl.waf.visibility_config[0].cloudwatch_metrics_enabled == true
    error_message = "WAF should have CloudWatch metrics enabled"
  }

  assert {
    condition     = aws_wafv2_web_acl.waf.visibility_config[0].metric_name == "WebACLMetrics"
    error_message = "WAF should have correct metric name"
  }

  assert {
    condition     = aws_wafv2_web_acl.waf.visibility_config[0].sampled_requests_enabled == true
    error_message = "WAF should have sampled requests enabled"
  }
}

run "waf_managed_rule_configuration" {
  assert {
    condition     = length(aws_wafv2_web_acl.waf.rule) == 1
    error_message = "WAF should have exactly one rule configured"
  }

  assert {
    condition     = contains([for rule in aws_wafv2_web_acl.waf.rule : rule.name], "AWS-AWSManagedRulesKnownBadInputsRuleSet")
    error_message = "WAF rule should have correct name"
  }

  assert {
    condition     = contains([for rule in aws_wafv2_web_acl.waf.rule : rule.priority], 1)
    error_message = "WAF rule should have priority 1"
  }

  assert {
    condition     = length([for rule in aws_wafv2_web_acl.waf.rule : rule.override_action if length(rule.override_action) > 0 && rule.override_action[0].none != null]) == 1
    error_message = "WAF rule should have override action set to none"
  }
}

run "waf_rule_statement_configuration" {
  assert {
    condition     = length([for rule in aws_wafv2_web_acl.waf.rule : rule.statement[0].managed_rule_group_statement[0].name if rule.statement[0].managed_rule_group_statement[0].name == "AWSManagedRulesKnownBadInputsRuleSet"]) == 1
    error_message = "WAF rule should use AWS managed rule group for known bad inputs"
  }

  assert {
    condition     = length([for rule in aws_wafv2_web_acl.waf.rule : rule.statement[0].managed_rule_group_statement[0].vendor_name if rule.statement[0].managed_rule_group_statement[0].vendor_name == "AWS"]) == 1
    error_message = "WAF rule should use AWS as vendor"
  }
}

run "waf_rule_visibility_configuration" {
  assert {
    condition     = length([for rule in aws_wafv2_web_acl.waf.rule : rule.visibility_config[0].cloudwatch_metrics_enabled if rule.visibility_config[0].cloudwatch_metrics_enabled == true]) == 1
    error_message = "WAF rule should have CloudWatch metrics enabled"
  }

  assert {
    condition     = length([for rule in aws_wafv2_web_acl.waf.rule : rule.visibility_config[0].sampled_requests_enabled if rule.visibility_config[0].sampled_requests_enabled == true]) == 1
    error_message = "WAF rule should have sampled requests enabled"
  }

  assert {
    condition     = contains([for rule in aws_wafv2_web_acl.waf.rule : rule.visibility_config[0].metric_name], "WebACLMetrics-badinputs")
    error_message = "WAF rule should have correct metric name with suffix"
  }
}

run "waf_associations_configuration" {
  assert {
    condition     = length(aws_wafv2_web_acl_association.association) == 2
    error_message = "Should create 2 WAF associations"
  }

  assert {
    condition     = aws_wafv2_web_acl_association.association[0].resource_arn == "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/test-alb/1234567890123456"
    error_message = "First association should use correct ALB ARN"
  }

  assert {
    condition     = aws_wafv2_web_acl_association.association[1].resource_arn == "arn:aws:apigateway:us-east-1::/restapis/test-api/stages/prod"
    error_message = "Second association should use correct API Gateway ARN"
  }

  assert {
    condition     = aws_wafv2_web_acl_association.association[0].web_acl_arn == aws_wafv2_web_acl.waf.arn
    error_message = "Association should reference the WAF Web ACL ARN"
  }
}

run "staging_environment" {
  variables {
    environment = "stg"
  }

  assert {
    condition     = aws_wafv2_web_acl.waf.name == "web-firewall-anysource-stg"
    error_message = "WAF should use staging environment in name"
  }

  assert {
    condition     = aws_wafv2_web_acl.waf.description == "waf that for web-firewall in env stg"
    error_message = "WAF should use staging environment in description"
  }
}

run "disabled_metrics_and_sampling" {
  variables {
    cloudwatch_metrics = false
    sampled_requests = false
  }

  assert {
    condition     = aws_wafv2_web_acl.waf.visibility_config[0].cloudwatch_metrics_enabled == false
    error_message = "WAF should have CloudWatch metrics disabled when variable is false"
  }

  assert {
    condition     = aws_wafv2_web_acl.waf.visibility_config[0].sampled_requests_enabled == false
    error_message = "WAF should have sampled requests disabled when variable is false"
  }

  assert {
    condition     = length([for rule in aws_wafv2_web_acl.waf.rule : rule.visibility_config[0].cloudwatch_metrics_enabled if rule.visibility_config[0].cloudwatch_metrics_enabled == false]) == 1
    error_message = "WAF rule should have CloudWatch metrics disabled when variable is false"
  }

  assert {
    condition     = length([for rule in aws_wafv2_web_acl.waf.rule : rule.visibility_config[0].sampled_requests_enabled if rule.visibility_config[0].sampled_requests_enabled == false]) == 1
    error_message = "WAF rule should have sampled requests disabled when variable is false"
  }
}

run "single_resource_association" {
  variables {
    resources_arn = ["arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/single-alb/1234567890123456"]
  }

  assert {
    condition     = length(aws_wafv2_web_acl_association.association) == 1
    error_message = "Should create only 1 WAF association for single resource"
  }

  assert {
    condition     = aws_wafv2_web_acl_association.association[0].resource_arn == "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/single-alb/1234567890123456"
    error_message = "Single association should use correct resource ARN"
  }
}

run "custom_metric_name" {
  variables {
    metric_name = "CustomFirewallMetrics"
  }

  assert {
    condition     = aws_wafv2_web_acl.waf.visibility_config[0].metric_name == "CustomFirewallMetrics"
    error_message = "WAF should use custom metric name"
  }

  assert {
    condition     = contains([for rule in aws_wafv2_web_acl.waf.rule : rule.visibility_config[0].metric_name], "CustomFirewallMetrics-badinputs")
    error_message = "WAF rule should use custom metric name with suffix"
  }
}

run "different_project_and_name" {
  variables {
    project = "testproject"
    name = "api-protection"
  }

  assert {
    condition     = aws_wafv2_web_acl.waf.name == "api-protection-testproject-production"
    error_message = "WAF should use different project and name"
  }

  assert {
    condition     = aws_wafv2_web_acl.waf.description == "waf that for api-protection in env production"
    error_message = "WAF description should use different name"
  }
}

run "empty_resources_list" {
  variables {
    resources_arn = []
  }

  assert {
    condition     = length(aws_wafv2_web_acl_association.association) == 0
    error_message = "Should create no associations when resources list is empty"
  }
}