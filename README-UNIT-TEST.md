# Terraform Module Unit Testing

This repository includes a comprehensive testing framework for Terraform modules using the native `terraform test` command introduced in Terraform 1.6+ but we need terraform 1.12+ for all the features to work.

## Overview

Each Terraform module in the `modules/` directory can have associated tests that validate the module's functionality, configuration, and outputs. Tests are written using HashiCorp Configuration Language (HCL) and use mock providers to avoid creating real infrastructure.

## Test Structure

Tests for each module are located in `modules/<module-name>/tests/` directory:
```
modules/
  acm/
    tests/
      acm_certificate.tftest.hcl
  alb/
    tests/
      alb.tftest.hcl
  waf/
    tests/
      waf.tftest.hcl
  ...
```

## Running Tests

### Using the Test Script

The repository includes a test runner script at `scripts/run-tests.sh` that provides an easy way to run tests for one or more modules.

#### Run tests for all modules:
```bash
./scripts/run-tests.sh
```

#### Run tests for specific modules:
```bash
./scripts/run-tests.sh waf vpc alb
```

#### Run tests for a single module:
```bash
./scripts/run-tests.sh rds
```

The script will:
- Initialize Terraform in each module directory
- Run `terraform test` for modules with test files
- Provide colored output showing pass/fail status
- Display a summary of test results
- Skip modules that don't have tests

### Running Tests Manually

You can also run tests manually for any module:

1. Navigate to the module directory:
   ```bash
   cd modules/waf
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Run the tests:
   ```bash
   terraform test
   ```

## GitHub Actions Integration

The repository includes automated testing via GitHub Actions in `.github/workflows/terraform-module-tests.yml`.

### How it Works

The GitHub Action:
1. **Change Detection**: Uses `git diff` to identify which modules have been modified in a pull request
2. **Matrix Strategy**: Runs tests in parallel for each changed module
3. **Terraform Setup**: Installs the specified version of Terraform (~1.12)
4. **Test Execution**: Runs the test script for each modified module
5. **Results Reporting**: Provides detailed test results and summaries

### Trigger Conditions

The action runs when:
- Pull requests are opened, synchronized, or reopened
- Changes are pushed to the `main` branch
- Only when files in the `modules/` directory are modified

### Example Workflow

When you modify files in `modules/waf/` and `modules/vpc/`, the action will:
1. Detect changes in both modules
2. Create a test matrix with `["waf", "vpc"]`
3. Run tests for both modules in parallel
4. Report results for each module
5. Provide an overall summary

## Test Framework Features

### Mock Providers
Tests use mock AWS providers to simulate resources without creating real infrastructure:
```hcl
mock_provider "aws" {
  mock_resource "aws_wafv2_web_acl" {
    defaults = {
      arn = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/test-web-acl/1234567890123456"
      id  = "1234567890123456"
    }
  }
}
```

### Global Variables with Local Overrides
Tests define global variables that can be overridden in specific test runs:
```hcl
variables {
  project = "anysource"
  environment = "production"
  name = "web-firewall"
}

run "staging_environment" {
  variables {
    environment = "stg"  # Override for this test
  }
  # assertions...
}
```

### Comprehensive Coverage
Each module's tests typically cover:
- Resource configuration validation
- Variable handling and validation
- Environment-specific behavior
- Edge cases and error conditions
- Output verification

## Adding Tests for New Modules

To add tests for a new module:

1. Create a tests directory:
   ```bash
   mkdir modules/your-module/tests
   ```

2. Create a test file (e.g., `your-module.tftest.hcl`):
   ```hcl
   mock_provider "aws" {}
   
   variables {
     # Define default test variables
   }
   
   run "basic_configuration" {
     assert {
       condition     = # your assertion
       error_message = "Error message"
     }
   }
   ```

3. Run the tests to verify they work:
   ```bash
   ./scripts/run-tests.sh your-module
   ```

## Requirements

- **Terraform**: Version 1.6+ (for `terraform test` command)
- **Platform**: The test script is designed for Unix-like systems (Linux/macOS)
- **Dependencies**: No additional dependencies required beyond Terraform

## Troubleshooting

### Common Issues

1. **"terraform command not found"**: Ensure Terraform is installed and in your PATH
2. **"Module not found"**: Check that the module name matches the directory name in `modules/`
3. **Test failures**: Review the specific assertion that failed and check module configuration

### Getting Help

- Use `./scripts/run-tests.sh --help` to see usage information
- Check the GitHub Actions logs for CI/CD test failures
- Review individual test files for specific test requirements and assertions