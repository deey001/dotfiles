#!/bin/bash
set -euo pipefail

# ==============================================================================
# test.sh — Dotfiles Validation and Testing Script
# ==============================================================================
# Validates that dotfiles are correctly installed, symlinks point to the right
# targets, required/optional tools are available, config files parse without
# errors, and file permissions are secure.
#
# USAGE:
#   ./test.sh                    # Run all tests
#   ./test.sh --verbose          # Run with detailed output (shows symlink targets)
#   make test                    # Via Makefile (equivalent to ./test.sh)
#   make test-verbose            # Via Makefile (equivalent to ./test.sh --verbose)
#
# WHAT IT TESTS:
#   [1/4] Symlinks  — Each dotfile in $HOME points back to the repo
#   [2/4] Commands  — Core tools (bash, git, tmux, nvim, starship) are installed
#   [3/4] Optional  — Modern CLI replacements (eza, bat, fzf, zoxide, rg)
#   [4/4] Syntax    — bash -n on all Bash config files; directory permissions
#
# EXIT CODES:
#   0 - All tests passed
#   1 - One or more tests failed
#
# DEPENDENCIES:
#   • bash, stat, readlink (standard coreutils)
#   • The dotfiles must already be installed (via install.sh or stow)
#
# SUGGESTED ADDITIONAL TESTS:
#   TODO: Check that ~/.local/bin is on PATH (required for ble.sh, starship, etc.)
#   TODO: Verify bash-completion version >= 2.12 (needed for bash 5.2 compat)
#   TODO: Check ble.sh is installed (~/.local/share/blesh/ble.sh exists)
#   TODO: Verify starship.toml is valid (starship config check, if available)
#   TODO: Check tmux plugin manager is installed (~/.tmux/plugins/tpm)
# ==============================================================================

# ---- ANSI color codes for terminal output ------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color — resets terminal formatting

# ---- Test counters -----------------------------------------------------------
# Incremented by test_result() to track pass/fail totals for the summary
TESTS_PASSED=0
TESTS_FAILED=0
VERBOSE=0

# Enable verbose mode to show symlink targets and version strings on passing tests
if [[ "${1:-}" == "--verbose" ]]; then
    VERBOSE=1
fi

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------
# These functions encapsulate the test logic so the "Run Tests" section below
# reads like a declarative checklist rather than procedural code.
# ------------------------------------------------------------------------------

# Print a test result with color-coded pass/fail indicator.
# Args: $1=test name, $2=result (0=pass, non-zero=fail), $3=optional details
test_result() {
    local test_name="$1"
    local result="$2"
    local details="${3:-}"

    if [ "$result" -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        if [ $VERBOSE -eq 1 ] && [ -n "$details" ]; then
            echo "  └─ $details"
        fi
    else
        echo -e "${RED}✗${NC} $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        if [ -n "$details" ]; then
            echo "  └─ $details"
        fi
    fi
}

# Verify a symlink exists and its target contains the expected path fragment.
# Uses substring match (*"$expected_target"*) so both absolute and relative
# symlink targets work (stow creates relative links, manual ln -s may not).
# Args: $1=link path in $HOME, $2=expected target substring
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

# Verify a command is on PATH and optionally capture its --version output.
# Args: $1=command name
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

# Verify file permissions match expected octal value.
# Uses stat -c on Linux and stat -f on macOS (BSD) for portability.
# Args: $1=file path, $2=expected permissions as octal string (e.g., "600")
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

# Validate Bash syntax without executing the file (bash -n = "noexec" mode).
# This catches parse errors (unmatched quotes, missing fi/done, etc.) that
# would prevent the shell from starting if the file were sourced.
# Args: $1=path to bash file
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

# ---- Test 1: Symlink verification --------------------------------------------
# Ensures every dotfile in $HOME is a symlink pointing back into the repo.
echo -e "${YELLOW}[1/4] Checking Symlinks${NC}"
check_symlink "$HOME/.bashrc" "home/bash/.bashrc"
check_symlink "$HOME/.bash_aliases" "home/bash/.bash_aliases"
check_symlink "$HOME/.bash_profile" "home/bash/.bash_profile"
check_symlink "$HOME/.blerc" "home/bash/.blerc"
check_symlink "$HOME/.config/tmux/tmux.conf" "home/config/.config/tmux/tmux.conf"
check_symlink "$HOME/.gitconfig" "home/git/.gitconfig"
check_symlink "$HOME/.inputrc" "home/shell/.inputrc"
check_symlink "$HOME/.config/starship.toml" "home/config/.config/starship.toml"
check_symlink "$HOME/.config/nvim/init.lua" "home/config/.config/nvim/init.lua"
check_symlink "$HOME/.config/wezterm/wezterm.lua" "home/config/.config/wezterm/wezterm.lua"

# Only check .zshrc if zsh is installed — not all machines have it
if command -v zsh >/dev/null 2>&1; then
    check_symlink "$HOME/.zshrc" "home/zsh/.zshrc"
fi

# Optional .config subdirectories — these may not exist on minimal installs
if [ -d "$HOME/.config/bat" ]; then
    check_symlink "$HOME/.config/bat/themes/Catppuccin Mocha.tmTheme" "home/config/.config/bat/themes/Catppuccin Mocha.tmTheme" || true
fi
if [ -d "$HOME/.config/fastfetch" ]; then
    check_symlink "$HOME/.config/fastfetch/config.jsonc" "home/config/.config/fastfetch/config.jsonc" || true
fi
echo ""

# ---- Test 2: Required commands -----------------------------------------------
# These are the core tools that must be present for the dotfiles to function.
# Failure here means the install script didn't complete successfully.
echo -e "${YELLOW}[2/4] Checking Required Commands${NC}"
check_command "bash"
check_command "git"
check_command "tmux"
check_command "nvim"
check_command "starship"
echo ""

# ---- Test 3: Optional modern CLI replacements --------------------------------
# These enhance the shell experience but aren't strictly required.
# Failures here are informational — the dotfiles fall back to standard tools
# via `command -v` guards in .bash_aliases.
echo -e "${YELLOW}[3/4] Checking Optional Tools${NC}"
check_command "eza" || true          # ls replacement (aliased as ls/ll/la)
check_command "bat" || check_command "batcat" || true  # cat replacement (Debian names it batcat)
check_command "fzf" || true          # fuzzy finder (Ctrl-R history, file picker)
check_command "zoxide" || true       # cd replacement (learns frequent directories)
check_command "ripgrep" || check_command "rg" || true   # grep replacement
echo ""

# ---- Test 4: Config syntax & permissions -------------------------------------
# Runs bash -n on every sourced file. A syntax error in .bashrc would prevent
# login — catching it here avoids shell lockout.
echo -e "${YELLOW}[4/4] Validating Config Syntax${NC}"
check_bash_syntax "$HOME/.bashrc"
check_bash_syntax "$HOME/.bash_aliases"
check_bash_syntax "$HOME/.bash_profile"
check_bash_syntax "$HOME/.blerc"

# Directory permissions check (optional, can be expanded for other sensitive dirs)
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
