.PHONY: test test-storage test-utils test-detect test-executor test-all clean-test

# Run all tests
test:
	@echo "Running all tests..."
	@./tests/run_tests.sh

# Run specific test suites
test-storage:
	@./tests/run_tests.sh storage

test-utils:
	@./tests/run_tests.sh utils

test-detect:
	@./tests/run_tests.sh detect

test-executor:
	@./tests/run_tests.sh executor

# Run all tests verbosely
test-all: test

# Clean test artifacts
clean-test:
	@echo "Cleaning test artifacts..."
	@rm -f /tmp/neo-c-test-output.txt
	@rm -rf /tmp/tmp.* 2>/dev/null || true

# Help target
help:
	@echo "Available targets:"
	@echo "  make test           - Run all tests"
	@echo "  make test-storage   - Run storage tests only"
	@echo "  make test-utils     - Run utils tests only"
	@echo "  make test-detect    - Run detect tests only"
	@echo "  make test-executor  - Run executor tests only"
	@echo "  make clean-test     - Clean test artifacts"
