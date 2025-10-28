# Repository Synchronization Script

A comprehensive Bash script for synchronizing repositories across multiple GitHub organizations with robust error handling, logging, and retry mechanisms.

## Overview

This script automates the synchronization of repositories across three GitHub organizations:

1. **EmergentMonk** → Clones all repositories and creates/updates **TEST** branches
2. **multimodalas** → Clones all repositories and creates/updates **DEV** branches  
3. **QSOLKCB** → Forks all repositories from both organizations and pushes TEST/DEV branches to **BUILD** branch

## Features

- ✅ **Robust Error Handling**: Uses `set -euo pipefail` for strict error checking
- ✅ **Comprehensive Logging**: Timestamped logs with different levels (INFO, WARN, ERROR, DEBUG)
- ✅ **Retry Logic**: Configurable retry mechanism with exponential backoff
- ✅ **Dry Run Mode**: Test the script without making actual changes
- ✅ **Progress Tracking**: Clear progress messages and final success confirmation
- ✅ **Automatic Branch Creation**: Creates missing branches automatically
- ✅ **Skip Failed Repos**: Gracefully skips already-processed repositories
- ✅ **Authentication Checks**: Verifies GitHub CLI authentication before starting
- ✅ **Flexible Configuration**: Command-line options for customization

## Prerequisites

Before running the script, ensure you have:

1. **GitHub CLI (gh)** installed and authenticated:
   ```bash
   # Install GitHub CLI (if not already installed)
   brew install gh  # macOS
   # or
   curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
   sudo apt update && sudo apt install gh  # Ubuntu/Debian

   # Authenticate with GitHub
   gh auth login
   ```

2. **Git** configured with appropriate credentials:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

3. **Write access** to the target organizations:
   - Read access to `EmergentMonk` and `multimodalas` organizations
   - Write access to `QSOLKCB` organization for forking

## Installation

1. Clone this repository or download the script:
   ```bash
   wget https://raw.githubusercontent.com/EmergentMonk/codex/main/scripts/repo_sync.sh
   chmod +x repo_sync.sh
   ```

2. Or if you have the repository cloned:
   ```bash
   cd /path/to/codex
   chmod +x scripts/repo_sync.sh
   ```

## Usage

### Basic Usage

```bash
# Run full synchronization
./scripts/repo_sync.sh

# Dry run (recommended first time)
./scripts/repo_sync.sh --dry-run

# Verbose logging
./scripts/repo_sync.sh --verbose

# Custom retry count
./scripts/repo_sync.sh --retry-count 5

# Combined options
./scripts/repo_sync.sh --dry-run --verbose --retry-count 3
```

### Command Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `--dry-run` | Only list repositories, don't perform operations | `false` |
| `--verbose` | Enable verbose/debug logging | `false` |
| `--retry-count N` | Number of retries for failed operations | `3` |
| `--help` | Show help message and exit | - |

### Directory Structure

The script creates and uses the following directory structure:

```
${HOME}/repo_mirror/
├── repo_sync.log           # Main log file
├── repository1/            # Cloned repository
│   └── .repo_sync_skip     # Skip marker (if repo failed)
├── repository2/
└── ...
```

## Examples

### 1. First Time Setup (Recommended)

```bash
# Test with dry run first
./scripts/repo_sync.sh --dry-run --verbose

# If everything looks good, run the actual sync
./scripts/repo_sync.sh --verbose
```

### 2. Regular Synchronization

```bash
# Standard run with default settings
./scripts/repo_sync.sh

# Or with some additional retries for flaky connections
./scripts/repo_sync.sh --retry-count 5
```

### 3. Debugging Issues

```bash
# Enable verbose logging to debug issues
./scripts/repo_sync.sh --verbose --retry-count 1

# Check the log file for detailed information
tail -f ~/repo_mirror/repo_sync.log
```

## Workflow Details

The script performs the following steps for each organization:

1. **Authentication Check**: Verifies GitHub CLI is authenticated
2. **Repository Discovery**: Lists all repositories in the source organization
3. **For Each Repository**:
   - Clone or update the local repository
   - Create/checkout the target branch (TEST or DEV)
   - Fork the repository to QSOLKCB organization (if not already forked)
   - Add the QSOLKCB fork as a remote named "build"
   - Push the branch to QSOLKCB as the "BUILD" branch
4. **Error Handling**: Skip failed repositories and continue with others
5. **Progress Reporting**: Log all operations with timestamps

### Branch Mapping

| Source Organization | Source Branch | Target Organization | Target Branch |
|---------------------|---------------|-------------------|---------------|
| EmergentMonk | main/master → TEST | QSOLKCB | BUILD |
| multimodalas | main/master → DEV | QSOLKCB | BUILD |

## Error Handling

The script includes comprehensive error handling:

- **Strict Error Mode**: `set -euo pipefail` ensures the script exits on any error
- **Retry Logic**: Failed operations are retried with exponential backoff
- **Skip Markers**: Failed repositories are marked to skip in subsequent runs
- **Graceful Degradation**: Individual repository failures don't stop the entire process
- **Detailed Logging**: All errors are logged with timestamps for debugging

### Common Issues and Solutions

1. **Authentication Failed**
   ```bash
   # Re-authenticate with GitHub CLI
   gh auth login
   ```

2. **Repository Access Denied**
   - Ensure you have read access to source organizations
   - Ensure you have write access to QSOLKCB organization

3. **Network Issues**
   ```bash
   # Increase retry count for flaky connections
   ./scripts/repo_sync.sh --retry-count 10
   ```

4. **Disk Space Issues**
   ```bash
   # Clean up old mirrors
   rm -rf ~/repo_mirror
   ```

## Logging

The script provides multiple levels of logging:

- **INFO**: General progress and status messages
- **WARN**: Non-fatal issues that don't stop execution
- **ERROR**: Fatal errors that require attention
- **DEBUG**: Detailed information (only shown with `--verbose`)

Log format:
```
[2025-10-28 17:55:31] [INFO] Starting repository synchronization script
[2025-10-28 17:55:32] [DEBUG] Ensuring branch 'TEST' exists
[2025-10-28 17:55:33] [WARN] Failed to pull latest changes for branch 'TEST', continuing with local version
[2025-10-28 17:55:34] [ERROR] Failed to process repository: EmergentMonk/example-repo
```

## Configuration

You can modify the following variables at the top of the script:

```bash
ORG_TEST="EmergentMonk"      # Source org for TEST branch
ORG_DEV="multimodalas"       # Source org for DEV branch  
ORG_BUILD="QSOLKCB"          # Target org for BUILD branch
TMPDIR="${HOME}/repo_mirror" # Working directory
MAX_REPOS=200                # Maximum repositories to process per org
```

## Troubleshooting

### Check Prerequisites

```bash
# Verify GitHub CLI is installed and authenticated
gh --version
gh auth status

# Verify Git is configured
git config --global user.name
git config --global user.email
```

### Manual Testing

```bash
# Test individual operations manually
gh repo list EmergentMonk --limit 5
gh repo list multimodalas --limit 5
gh repo fork EmergentMonk/codex --org=QSOLKCB --dry-run
```

### Log Analysis

```bash
# View recent logs
tail -n 50 ~/repo_mirror/repo_sync.log

# Search for errors
grep ERROR ~/repo_mirror/repo_sync.log

# Follow logs in real-time
tail -f ~/repo_mirror/repo_sync.log
```

## Security Considerations

- The script uses SSH for Git operations (`git@github.com`)
- Ensure your SSH keys are properly configured for GitHub
- The script requires write access to the target organization
- All operations are logged for audit purposes

## Contributing

To contribute to this script:

1. Test your changes with `--dry-run` first
2. Ensure error handling is maintained
3. Add appropriate logging for new features
4. Update this README if adding new options or features

## License

This script is part of the Codex repository and follows the same license terms.