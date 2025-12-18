#!/bin/bash
set -euo pipefail

# ==============================================================================
# test.sh - Dotfiles Validation and Testing Script
# ==============================================================================
# This script validates that dotfiles are correctly installed and that all
# required tools are available.
#
# USAGE:
#   ./test.sh                    # Run all tests
#   ./test.sh --verbose          # Run with detailed output
#
# WHAT IT TESTS:
#   1. Symlinks are created correctly
#   2. Required commands are installed
#   3. Config files have valid syntax
#   4. File permissions are correct
#
# EXIT CODES:
#   0 - All tests passed
#   1 - One or more tests failed
# ==============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
VERBOSE=0

# Check for verbose flag
if [[ "${1:-}" == "--verbose" ]]; then
    VERBOSE=1
fi

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

# Print test result
test_result() {
    local test_name="$1"
    local result="$2"
    local details="${3:-}"

    if [ "$result" -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
        if [ $VERBOSE -eq 1 ] && [ -n "$details" ]; then
            echo "  └─ $details"
        fi
    else
        echo -e "${RED}✗${NC} $test_name"
        ((TESTS_FAILED++))
        if [ -n "$details" ]; then
            echo "  └─ $details"
        fi
    fi
}

# Check if symlink exists and points to correct location
check_symlink() {
    local link_path="$1"
    local expected_target="$2"
    local test_name="Symlink: $link_path"

    if [ -L "$link_path" ]; then
        local actual_target
        actual_target=$(readlink "$link_path")
        if [[ "$actual_target" == *"$expected_target"* ]]; then
            test_result "$test_name" 0 "→ $actual_target"
            return 0
        else
            test_result "$test_name" 1 "Points to $actual_target (expected $expected_target)"
            return 1
        fi
    else
        test_result "$test_name" 1 "Not a symlink or doesn't exist"
        return 1
    fi
}

# Check if command is available
check_command() {
    local cmd="$1"
    local test_name="Command: $cmd"

    if command -v "$cmd" >/dev/null 2>&1; then
        local version
        version=$("$cmd" --version 2>&1 | head -n 1 || echo "installed")
        test_result "$test_name" 0 "$version"
        return 0
    else
        test_result "$test_name" 1 "Not installed"
        return 1
    fi
}

# Check file permissions
check_permissions() {
    local file_path="$1"
    local expected_perms="$2"
    local test_name="Permissions: $file_path"

    if [ -e "$file_path" ]; then
        local actual_perms
        actual_perms=$(stat -c "%a" "$file_path" 2>/dev/null || stat -f "%Lp" "$file_path" 2>/dev/null)
        if [ "$actual_perms" = "$expected_perms" ]; then
            test_result "$test_name" 0 "$actual_perms"
            return 0
        else
            test_result "$test_name" 1 "Has $actual_perms (expected $expected_perms)"
            return 1
        fi
    else
        test_result "$test_name" 1 "File doesn't exist"
        return 1
    fi
}

# Validate bash syntax
check_bash_syntax() {
    local file_path="$1"
    local test_name="Bash syntax: $(basename "$file_path")"

    if [ -f "$file_path" ]; then
        if bash -n "$file_path" 2>/dev/null; then
            test_result "$test_name" 0 "Valid"
            return 0
        else
            test_result "$test_name" 1 "Syntax errors found"
            return 1
        fi
    else
        test_result "$test_name" 1 "File doesn't exist"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Run Tests
# ------------------------------------------------------------------------------

echo "======================================================================"
echo "Dotfiles Validation Test Suite"
echo "======================================================================"
echo ""

# Test 1: Check symlinks
echo -e "${YELLOW}[1/4] Checking Symlinks${NC}"
check_symlink "$HOME/.bashrc" ".bashrc"
check_symlink "$HOME/.bash_aliases" ".bash_aliases"
check_symlink "$HOME/.bash_exports" ".bash_exports"
check_symlink "$HOME/.bash_functions" ".bash_functions"
check_symlink "$HOME/.tmux.conf" ".tmux.conf"
check_symlink "$HOME/.gitconfig" ".gitconfig"
check_symlink "$HOME/.inputrc" ".inputrc"
check_symlink "$HOME/.config/starship.toml" "starship.toml"
check_symlink "$HOME/.config/nvim/init.lua" "init.lua"
echo ""

# Test 2: Check required commands
echo -e "${YELLOW}[2/4] Checking Required Commands${NC}"
check_command "bash"
check_command "git"
check_command "tmux"
check_command "nvim"
check_command "starship"
echo ""

# Test 3: Check optional modern tools
echo -e "${YELLOW}[3/4] Checking Optional Tools${NC}"
check_command "eza" || true
check_command "bat" || check_command "batcat" || true
check_command "fzf" || true
check_command "zoxide" || true
check_command "ripgrep" || check_command "rg" || true
echo ""

# Test 4: Validate config syntax
echo -e "${YELLOW}[4/4] Validating Config Syntax${NC}"
check_bash_syntax "$HOME/.bashrc"
check_bash_syntax "$HOME/.bash_aliases"
check_bash_syntax "$HOME/.bash_exports"
check_bash_syntax "$HOME/.bash_functions"

# Check SSH permissions if exists
if [ -f "$HOME/.ssh/config" ]; then
    check_permissions "$HOME/.ssh/config" "600" || true
fi
if [ -d "$HOME/.ssh" ]; then
    check_permissions "$HOME/.ssh" "700" || true
fi
echo ""

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------

echo "======================================================================"
echo "Test Results:"
echo -e "  ${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "  ${RED}Failed:${NC} $TESTS_FAILED"
echo "======================================================================"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please review the output above.${NC}"
    exit 1
fi
