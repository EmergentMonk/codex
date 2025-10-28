#!/bin/bash
set -euo pipefail

# Repository mirroring script for processing organizations and their repositories
# This script processes repositories from test and development organizations,
# creates appropriate branches, and mirrors them to a build organization.
#
# Usage: ./process_org_repos.sh
#
# Prerequisites:
# - GitHub CLI (gh) must be installed and authenticated
# - SSH access to GitHub repositories must be configured
# - Write access to the target build organization (QSOLKCB)
#
# The script performs the following operations:
# 1. Clones repositories from EmergentMonk org and creates/updates TEST branch
# 2. Clones repositories from multimodalas org and creates/updates DEV branch  
# 3. Forks repositories to QSOLKCB org and pushes the respective branches

ORG_TEST="EmergentMonk"
ORG_DEV="multimodalas"
ORG_BUILD="QSOLKCB"
TMPDIR="${HOME}/repo_mirror"

# Create temporary directory for repository operations
mkdir -p "$TMPDIR"
cd "$TMPDIR"

# Function to process repositories for a given organization
# Args:
#   $1 - Organization name
#   $2 - Target branch name
process_org() {
  local ORG="$1"
  local TARGET_BRANCH="$2"
  
  # Get list of repositories for the organization
  for repo in $(gh repo list "$ORG" --limit 200 --json name -q '.[].name'); do
    echo "=== Processing $ORG/$repo → branch $TARGET_BRANCH ==="
    
    # Clean up any existing directory to avoid conflicts (safely scoped to current dir)
    rm -rf "./$repo"
    
    # Clone the repository
    gh repo clone "$ORG/$repo" "$repo"
    cd "$repo"
    
    # Check if the target branch exists on the remote (exact match)
    if git ls-remote --heads origin "$TARGET_BRANCH" | grep -q "refs/heads/$TARGET_BRANCH$"; then
      # Branch exists, checkout and pull latest changes
      git checkout "$TARGET_BRANCH"
      git pull origin "$TARGET_BRANCH"
    else
      # Branch doesn't exist, create it
      git checkout -b "$TARGET_BRANCH"
      git push origin "$TARGET_BRANCH"
    fi
    
    # Fork the repository to the build organization
    echo "Forking into $ORG_BUILD/$repo"
    gh repo fork --org "$ORG_BUILD" || true
    
    # Add build remote and push the target branch
    git remote add build "git@github.com:$ORG_BUILD/$repo.git" || true
    git push build "$TARGET_BRANCH:$TARGET_BRANCH"
    
    cd ..
  done
}

# Process test organization repositories with TEST branch
process_org "$ORG_TEST" "TEST"

# Process development organization repositories with DEV branch
process_org "$ORG_DEV" "DEV"

echo "✅ All done"