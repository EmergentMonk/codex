#!/usr/bin/env bash
#
# Repository Synchronization Script
# ==================================
# 
# This script synchronizes repositories across multiple GitHub organizations:
# - Clones all repos from EmergentMonk org and pushes to TEST branch
# - Clones all repos from multimodalas org and pushes to DEV branch
# - Forks all repos to QSOLKCB org with both TEST and DEV pushed to BUILD branch
#
# Prerequisites:
# - GitHub CLI (gh) installed and authenticated
# - Git configured with appropriate credentials
# - Write access to target organizations
#
# Usage:
#   ./repo_sync.sh [--dry-run] [--verbose] [--retry-count N]
#
# Options:
#   --dry-run       Only list repositories, don't perform operations
#   --verbose       Enable verbose logging
#   --retry-count   Number of retries for failed operations (default: 3)
#
set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

ORG_TEST="EmergentMonk"      # Source org for TEST branch
ORG_DEV="multimodalas"       # Source org for DEV branch  
ORG_BUILD="QSOLKCB"          # Target org for BUILD branch
TMPDIR="${HOME}/repo_mirror" # Working directory
LOG_FILE="${TMPDIR}/repo_sync.log"

# Default options
DRY_RUN=false
VERBOSE=false
RETRY_COUNT=3
MAX_REPOS=200

# =============================================================================
# Utility Functions
# =============================================================================

# Print timestamped log message
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure log directory exists
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Print info message
info() {
    log "INFO" "$@"
}

# Print warning message
warn() {
    log "WARN" "$@"
}

# Print error message
error() {
    log "ERROR" "$@"
}

# Print verbose message (only if verbose mode enabled)
verbose() {
    if [[ "$VERBOSE" == true ]]; then
        log "DEBUG" "$@"
    fi
}

# Print usage information
usage() {
    cat << EOF
Repository Synchronization Script

Usage: $0 [OPTIONS]

This script synchronizes repositories across GitHub organizations:
- EmergentMonk → TEST branch
- multimodalas → DEV branch  
- Both organizations → QSOLKCB/BUILD branch

OPTIONS:
    --dry-run           Only list repositories, don't perform operations
    --verbose           Enable verbose logging
    --retry-count N     Number of retries for failed operations (default: 3)
    --help             Show this help message

EXAMPLES:
    $0                          # Run full synchronization
    $0 --dry-run               # List repositories only
    $0 --verbose --retry-count 5  # Verbose mode with 5 retries

PREREQUISITES:
    - GitHub CLI (gh) installed and authenticated
    - Git configured with appropriate credentials
    - Write access to target organizations

EOF
}

# Retry function with exponential backoff
retry_with_backoff() {
    local max_attempts="$1"
    local delay=1
    local attempt=1
    shift

    while [[ $attempt -le $max_attempts ]]; do
        if "$@"; then
            return 0
        fi
        
        if [[ $attempt -eq $max_attempts ]]; then
            error "Command failed after $max_attempts attempts: $*"
            return 1
        fi
        
        warn "Attempt $attempt failed, retrying in ${delay}s: $*"
        sleep $delay
        delay=$((delay * 2))
        attempt=$((attempt + 1))
    done
}

# Check if GitHub CLI is authenticated
check_gh_auth() {
    info "Checking GitHub CLI authentication..."
    if ! gh auth status >/dev/null 2>&1; then
        error "GitHub CLI not authenticated. Please run 'gh auth login' first."
        exit 1
    fi
    info "GitHub CLI authentication verified"
}

# Check if repository exists and is accessible
check_repo_access() {
    local org="$1"
    local repo="$2"
    
    if gh repo view "$org/$repo" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Create branch if it doesn't exist, or checkout if it does
ensure_branch() {
    local branch="$1"
    
    verbose "Ensuring branch '$branch' exists"
    
    if git rev-parse --verify "$branch" >/dev/null 2>&1; then
        verbose "Branch '$branch' exists, checking out"
        git checkout "$branch"
        git pull origin "$branch" || {
            warn "Failed to pull latest changes for branch '$branch', continuing with local version"
        }
    else
        verbose "Creating new branch '$branch'"
        git checkout -b "$branch"
        git push origin "$branch"
    fi
}

# Add remote if it doesn't exist
ensure_remote() {
    local remote_name="$1"
    local remote_url="$2"
    
    verbose "Ensuring remote '$remote_name' exists: $remote_url"
    
    if git remote get-url "$remote_name" >/dev/null 2>&1; then
        verbose "Remote '$remote_name' already exists"
        # Update remote URL in case it changed
        git remote set-url "$remote_name" "$remote_url"
    else
        verbose "Adding remote '$remote_name': $remote_url"
        git remote add "$remote_name" "$remote_url"
    fi
}

# =============================================================================
# Core Functions
# =============================================================================

# Get list of repositories for an organization
get_repo_list() {
    local org="$1"
    
    info "Fetching repository list for organization: $org"
    
    local repos
    repos=$(gh repo list "$org" --limit "$MAX_REPOS" --json name -q '.[].name' 2>/dev/null || true)
    
    if [[ -z "$repos" ]]; then
        warn "No repositories found for organization '$org' or access denied"
        return 1
    fi
    
    local repo_count
    repo_count=$(echo "$repos" | wc -l)
    info "Found $repo_count repositories in '$org'"
    
    echo "$repos"
}

# Clone or update a repository
clone_or_update_repo() {
    local org="$1"
    local repo="$2"
    local target_dir="$3"
    
    if [[ -d "$target_dir" ]]; then
        verbose "Repository '$repo' already exists, updating"
        cd "$target_dir"
        git fetch --all --prune
    else
        verbose "Cloning repository '$org/$repo'"
        retry_with_backoff "$RETRY_COUNT" gh repo clone "$org/$repo" "$target_dir"
        cd "$target_dir"
    fi
}

# Fork repository to target organization
fork_repo() {
    local source_org="$1"
    local repo="$2"
    local target_org="$3"
    
    verbose "Checking if fork '$target_org/$repo' already exists"
    
    if check_repo_access "$target_org" "$repo"; then
        verbose "Fork '$target_org/$repo' already exists"
        return 0
    fi
    
    info "Forking '$source_org/$repo' to '$target_org'"
    retry_with_backoff "$RETRY_COUNT" gh repo fork "$source_org/$repo" --org="$target_org" --remote --clone=false
}

# Process repositories for a single organization
process_org() {
    local source_org="$1"
    local target_branch="$2"
    local operation_name="$3"
    
    info "=== Starting $operation_name: $source_org → $target_branch ==="
    
    local repos
    if ! repos=$(get_repo_list "$source_org"); then
        error "Failed to get repository list for '$source_org'"
        return 1
    fi
    
    local processed=0
    local failed=0
    local skipped=0
    
    while IFS= read -r repo; do
        [[ -z "$repo" ]] && continue
        
        info "Processing repository: $source_org/$repo"
        
        # Skip if dry run
        if [[ "$DRY_RUN" == true ]]; then
            info "[DRY-RUN] Would process: $source_org/$repo → branch $target_branch"
            ((processed++))
            continue
        fi
        
        local repo_dir="$TMPDIR/$repo"
        
        # Check if we should skip this repo
        if [[ -f "$repo_dir/.repo_sync_skip" ]]; then
            info "Skipping repository '$repo' (marked to skip)"
            ((skipped++))
            continue
        fi
        
        if ! (
            # Run in subshell to isolate directory changes and potential failures
            set -e
            
            # Clone or update repository
            clone_or_update_repo "$source_org" "$repo" "$repo_dir"
            
            # Ensure target branch exists and is up to date
            ensure_branch "$target_branch"
            
            # Fork repository to build organization
            fork_repo "$source_org" "$repo" "$ORG_BUILD"
            
            # Set up remote for build organization
            local build_remote_url="git@github.com:$ORG_BUILD/$repo.git"
            ensure_remote "build" "$build_remote_url"
            
            # Push to build organization
            verbose "Pushing branch '$target_branch' to '$ORG_BUILD/$repo'"
            retry_with_backoff "$RETRY_COUNT" git push build "$target_branch:BUILD"
            
            verbose "Successfully processed: $source_org/$repo"
        ); then
            error "Failed to process repository: $source_org/$repo"
            ((failed++))
            
            # Create skip marker to avoid repeated failures
            mkdir -p "$repo_dir"
            touch "$repo_dir/.repo_sync_skip"
        else
            ((processed++))
        fi
        
        # Return to base directory
        cd "$TMPDIR"
        
    done <<< "$repos"
    
    info "=== Completed $operation_name ==="
    info "Processed: $processed, Failed: $failed, Skipped: $skipped"
    
    if [[ $failed -gt 0 ]]; then
        warn "$failed repositories failed during $operation_name"
        return 1
    fi
    
    return 0
}

# =============================================================================
# Main Function
# =============================================================================

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --retry-count)
                RETRY_COUNT="$2"
                shift 2
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Validate retry count
    if ! [[ "$RETRY_COUNT" =~ ^[0-9]+$ ]] || [[ "$RETRY_COUNT" -lt 1 ]]; then
        error "Invalid retry count: $RETRY_COUNT (must be positive integer)"
        exit 1
    fi
    
    # Initialize
    info "Starting repository synchronization script"
    info "Target directory: $TMPDIR"
    info "Dry run mode: $DRY_RUN"
    info "Verbose mode: $VERBOSE"
    info "Retry count: $RETRY_COUNT"
    
    # Create working directory and log file
    mkdir -p "$TMPDIR"
    # Ensure log file directory exists and create log file
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    cd "$TMPDIR"
    
    # Check prerequisites
    check_gh_auth
    
    # Main operations
    local overall_success=true
    
    # Process EmergentMonk → TEST
    if ! process_org "$ORG_TEST" "TEST" "EmergentMonk Processing"; then
        overall_success=false
    fi
    
    # Process multimodalas → DEV
    if ! process_org "$ORG_DEV" "DEV" "multimodalas Processing"; then
        overall_success=false
    fi
    
    # Final summary
    echo
    if [[ "$overall_success" == true ]]; then
        info "✅ Repository synchronization completed successfully!"
        info "All repositories have been processed and synchronized."
    else
        error "❌ Repository synchronization completed with errors!"
        error "Check the log file for details: $LOG_FILE"
        exit 1
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        info "This was a dry run. No actual changes were made."
    else
        info "Summary:"
        info "- EmergentMonk repositories → TEST branch → QSOLKCB/BUILD branch"
        info "- multimodalas repositories → DEV branch → QSOLKCB/BUILD branch"
        info "- Log file: $LOG_FILE"
        info "- Working directory: $TMPDIR"
    fi
}

# =============================================================================
# Script Entry Point
# =============================================================================

# Handle script interruption
trap 'error "Script interrupted by user"; exit 130' INT TERM

# Run main function
main "$@"