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

# Run tests
echo -e "${YELLOW}Running all tests...${NC}"
echo ""

if nvim --headless -u "$SCRIPT_DIR/minimal_init.lua" \
    -c "PlenaryBustedDirectory $SCRIPT_DIR { minimal_init = '$SCRIPT_DIR/minimal_init.lua' }" \
    2>&1 | tee /tmp/neo-c-test-output.txt; then
    EXIT_CODE=0
else
    EXIT_CODE=$?
fi

# Check if any tests failed
# Look for non-zero failures or errors in the summary lines
if grep -E "^Failed : " /tmp/neo-c-test-output.txt | grep -qv "Failed : 0" || \
   grep -E "^Errors : " /tmp/neo-c-test-output.txt | grep -qv "Errors : 0"; then
    echo ""
    echo "================================="
    echo -e "${RED}Some tests failed${NC}"
    echo "================================="
    exit 1
fi

if [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "================================="
    echo -e "${RED}Test execution error${NC}"
    echo "================================="
    exit 1
fi

echo ""
echo "================================="
echo -e "${GREEN}All tests passed!${NC}"
echo "================================="
exit 0
