#!/usr/bin/env bash
# Test runner for neo-c.nvim
#
# This script runs all tests using plenary.nvim's test harness
#
# Usage:
#   ./tests/run_tests.sh              # Run all tests
#   ./tests/run_tests.sh storage      # Run only storage tests
#   ./tests/run_tests.sh utils detect # Run utils and detect tests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if nvim is installed
if ! command -v nvim &> /dev/null; then
    echo -e "${RED}Error: nvim is not installed${NC}"
    exit 1
fi

# Check if plenary is installed
PLENARY_PATH="${HOME}/.local/share/nvim/site/pack/packer/start/plenary.nvim"
if [ ! -d "$PLENARY_PATH" ]; then
    PLENARY_PATH="${HOME}/.local/share/nvim/lazy/plenary.nvim"
    if [ ! -d "$PLENARY_PATH" ]; then
        echo -e "${YELLOW}Warning: plenary.nvim not found in standard locations${NC}"
        echo "Attempting to run tests anyway..."
    fi
fi

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${GREEN}Running neo-c.nvim tests...${NC}"
echo "Project root: $PROJECT_ROOT"
echo ""

# Build test file list
TEST_FILES=()
if [ $# -eq 0 ]; then
    # Run all tests
    TEST_FILES=("$SCRIPT_DIR"/*_spec.lua)
else
    # Run specific tests
    for test_name in "$@"; do
        test_file="$SCRIPT_DIR/${test_name}_spec.lua"
        if [ -f "$test_file" ]; then
            TEST_FILES+=("$test_file")
        else
            echo -e "${YELLOW}Warning: Test file not found: $test_file${NC}"
        fi
    done
fi

if [ ${#TEST_FILES[@]} -eq 0 ]; then
    echo -e "${RED}Error: No test files found${NC}"
    exit 1
fi

# Run each test file
FAILED=0
PASSED=0

for test_file in "${TEST_FILES[@]}"; do
    test_name=$(basename "$test_file" _spec.lua)
    echo -e "${YELLOW}Running ${test_name} tests...${NC}"

    if nvim --headless --noplugin -u NONE \
        -c "set rtp+=$PROJECT_ROOT" \
        -c "set rtp+=$PLENARY_PATH" \
        -c "runtime plugin/plenary.vim" \
        -c "lua require('plenary.test_harness').test_directory('$test_file', { minimal_init = '$SCRIPT_DIR/minimal_init.lua' })" \
        2>&1 | tee /tmp/neo-c-test-output.txt; then
        echo -e "${GREEN}✓ $test_name tests passed${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ $test_name tests failed${NC}"
        ((FAILED++))
    fi
    echo ""
done

# Summary
echo "================================="
echo -e "Test Summary:"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo "================================="

if [ $FAILED -gt 0 ]; then
    exit 1
fi

exit 0
