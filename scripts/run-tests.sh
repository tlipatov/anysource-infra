#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Initialize counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_MODULES=0

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$(dirname "$SCRIPT_DIR")/modules"

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "PASS")
            echo -e "${GREEN}[PASS]${NC} $message"
            ;;
        "FAIL")
            echo -e "${RED}[FAIL]${NC} $message"
            ;;
        "SKIP")
            echo -e "${YELLOW}[SKIP]${NC} $message"
            ;;
        "INFO")
            echo -e "${YELLOW}[INFO]${NC} $message"
            ;;
    esac
}

# Function to test a single module
test_module() {
    local module_path=$1
    local module_name=$(basename "$module_path")
    local original_dir=$(pwd)
    
    echo
    print_status "INFO" "Testing module: $module_name"
    
    # Check if module has test files
    if [ ! -d "$module_path/tests" ] && [ ! -f "$module_path"/*.tftest.hcl ]; then
        print_status "SKIP" "No test files found in $module_name"
        ((SKIPPED_MODULES++))
        return 0
    fi
    
    # Change to module directory
    cd "$module_path"
    
    # Run terraform init
    print_status "INFO" "Running terraform init for $module_name..."
    if ! terraform init -no-color > /dev/null 2>&1; then
        print_status "FAIL" "terraform init failed for $module_name"
        ((FAILED_TESTS++))
        ((TOTAL_TESTS++))
        return 0
    fi
    
    # Run terraform test
    print_status "INFO" "Running terraform test for $module_name..."
    if terraform test -no-color; then
        print_status "PASS" "$module_name tests passed"
        ((PASSED_TESTS++))
    else
        print_status "FAIL" "$module_name tests failed"
        ((FAILED_TESTS++))
    fi
    
    ((TOTAL_TESTS++))
    
    # Return to original directory
    cd "$original_dir" || exit 1
}

# Function to print usage
usage() {
    echo "Usage: $0 [module1] [module2] ..."
    echo "  If no modules are specified, all modules will be tested"
    echo "  Available modules:"
    for module in "$MODULES_DIR"/*/; do
        if [ -d "$module" ]; then
            echo "    - $(basename "$module")"
        fi
    done
    exit 1
}

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    print_status "FAIL" "terraform command not found. Please install Terraform."
    exit 1
fi

# Check if modules directory exists
if [ ! -d "$MODULES_DIR" ]; then
    print_status "FAIL" "Modules directory not found: $MODULES_DIR"
    exit 1
fi

echo "=== Terraform Module Test Runner ==="
echo "Modules directory: $MODULES_DIR"

# If specific modules are provided as arguments, test only those
if [ $# -gt 0 ]; then
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        usage
    fi
    
    print_status "INFO" "Testing specified modules: $*"
    for module_name in "$@"; do
        module_path="$MODULES_DIR/$module_name"
        if [ -d "$module_path" ]; then
            set +e  # Temporarily disable exit on error
            test_module "$module_path"
            set -e  # Re-enable exit on error
        else
            print_status "FAIL" "Module not found: $module_name"
            ((FAILED_TESTS++))
            ((TOTAL_TESTS++))
        fi
    done
else
    # Test all modules
    print_status "INFO" "Testing all modules in $MODULES_DIR"
    for module_path in "$MODULES_DIR"/*/; do
        if [ -d "$module_path" ]; then
            set +e  # Temporarily disable exit on error
            test_module "$module_path"
            set -e  # Re-enable exit on error
        fi
    done
fi

# Print summary
echo
echo "=== Test Summary ==="
echo "Total modules processed: $TOTAL_TESTS"
echo "Modules with tests passed: $PASSED_TESTS"
echo "Modules with tests failed: $FAILED_TESTS"
echo "Modules skipped (no tests): $SKIPPED_MODULES"

if [ $FAILED_TESTS -eq 0 ]; then
    print_status "PASS" "All tests completed successfully!"
    exit 0
else
    print_status "FAIL" "$FAILED_TESTS module(s) failed testing"
    exit 1
fi