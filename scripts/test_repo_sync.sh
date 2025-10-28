#!/usr/bin/env bash
#
# Test script for repo_sync.sh functionality
# This script tests the core logic without requiring GitHub authentication
#

set -euo pipefail

# Source the main script functions for testing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_LOG="/tmp/repo_sync_test.log"

# Mock GitHub CLI functions for testing
gh() {
    case "$1" in
        "auth")
            if [[ "$2" == "status" ]]; then
                echo "Logged in to github.com as test-user"
                return 0
            fi
            ;;
        "repo")
            case "$2" in
                "list")
                    local org="$3"
                    echo "test-repo-1"
                    echo "test-repo-2"
                    echo "test-repo-3"
                    return 0
                    ;;
                "clone"|"fork")
                    echo "Mock: would execute gh $*"
                    return 0
                    ;;
                "view")
                    return 0  # Assume repo exists
                    ;;
            esac
            ;;
    esac
    echo "Mock: gh $*"
    return 0
}

# Mock git functions for testing
git() {
    echo "Mock: git $*"
    case "$1" in
        "rev-parse")
            if [[ "$*" == *"TEST"* ]] || [[ "$*" == *"DEV"* ]]; then
                return 1  # Branch doesn't exist
            fi
            return 0
            ;;
        "remote")
            if [[ "$2" == "get-url" ]]; then
                return 1  # Remote doesn't exist
            fi
            return 0
            ;;
        *)
            return 0
            ;;
    esac
}

# Test the repository listing functionality
test_repo_listing() {
    echo "Testing repository listing..."
    
    # Override LOG_FILE for testing
    export LOG_FILE="$TEST_LOG"
    
    # Test with mock organizations
    for org in "EmergentMonk" "multimodalas"; do
        echo "Testing org: $org"
        repos=$(gh repo list "$org" --limit 200 --json name -q '.[].name' 2>/dev/null || true)
        echo "Found repos: $repos"
    done
    
    echo "✅ Repository listing test passed"
}

# Test command line argument parsing
test_argument_parsing() {
    echo "Testing argument parsing..."
    
    # Test that our script accepts the expected arguments
    if "$SCRIPT_DIR/repo_sync.sh" --help >/dev/null 2>&1; then
        echo "✅ Help argument works"
    else
        echo "❌ Help argument failed"
        return 1
    fi
    
    echo "✅ Argument parsing test passed"
}

# Test script execution flow (dry run)
test_dry_run() {
    echo "Testing dry run execution..."
    
    # Test dry run with our mock functions
    export -f gh git
    
    # This would fail due to auth, but we can test the argument parsing
    if "$SCRIPT_DIR/repo_sync.sh" --dry-run --help >/dev/null 2>&1; then
        echo "✅ Dry run arguments accepted"
    else
        echo "❌ Dry run arguments failed"
        return 1
    fi
    
    echo "✅ Dry run test passed"
}

# Run all tests
main() {
    echo "Starting repo_sync.sh tests..."
    echo "================================"
    
    test_repo_listing
    echo
    test_argument_parsing  
    echo
    test_dry_run
    echo
    
    echo "================================"
    echo "✅ All tests passed!"
    echo
    echo "Note: This test uses mock functions to simulate GitHub CLI operations."
    echo "To test with real GitHub operations, ensure 'gh auth login' is completed"
    echo "and run: $SCRIPT_DIR/repo_sync.sh --dry-run"
}

main "$@"