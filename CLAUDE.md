# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**claude-key-switch** is a cross-platform tool that rotates through multiple Anthropic API keys sequentially. It consists of POSIX-compliant shell scripts for macOS/Linux and PowerShell scripts for Windows. The tool reads keys from environment variables and updates the user's shell configuration file atomically.

### Core Architecture

The project consists of platform-specific scripts:

**macOS/Linux (POSIX):**
1. **claude-key-switch** (main executable) - Performs the key rotation logic
2. **install.sh** - Interactive installer that sets up environment variables and shell configuration

**Windows (PowerShell):**
1. **claude-key-switch.ps1** (main script) - PowerShell equivalent of the POSIX version
2. **Install-ClaudeKeySwitch.ps1** - Interactive PowerShell installer

### Key Design Principles

- **POSIX Compliance**: Uses `/bin/sh` (not bash-specific features) for maximum compatibility across macOS versions
- **Atomic Operations**: All file operations use temp files + `mv` or `awk` in-place replacement to ensure atomic updates
- **Environment-based Storage**: API keys are stored in environment variables (`CLAUDE_KEY_1`, `CLAUDE_KEY_2`, etc.) rather than files, preventing accidental commits and following security best practices
- **Idempotent Updates**: Uses marker comments (`# claude-key-switch START/END`) in shell configs to enable safe, repeatable updates without duplication

## Development Commands

### Testing the Main Script

```bash
# Run the key switcher (requires API keys set in environment)
./claude-key-switch

# Show help
./claude-key-switch --help

# Check version
./claude-key-switch --version
```

### Testing the Installer

```bash
# Run interactive installer
./install.sh
```

### Validating Shell Script Syntax

```bash
# Check syntax without executing (POSIX sh)
sh -n claude-key-switch
sh -n install.sh
```

### Manual Testing Workflow

```bash
# 1. Set up test environment variables
export CLAUDE_KEY_1='sk-ant-api03-test-key-1'
export CLAUDE_KEY_2='sk-ant-api03-test-key-2'
export CLAUDE_KEY_3='sk-ant-api03-test-key-3'

# 2. Run the switcher
./claude-key-switch

# 3. Verify the update in shell config
grep -A 1 "claude-key-switch START" ~/.zshrc  # or ~/.bash_profile

# 4. Check current index
cat .key-index

# 5. Clean up test state
rm .key-index
```

## Windows Development (PowerShell)

### Testing the PowerShell Scripts

```powershell
# Run the key switcher (requires API keys set in environment)
.\claude-key-switch.ps1

# Show help
Get-Help .\claude-key-switch.ps1 -Full
.\claude-key-switch.ps1 -Help

# Check version
.\claude-key-switch.ps1 -Version
```

### Testing the PowerShell Installer

```powershell
# Run interactive installer
.\Install-ClaudeKeySwitch.ps1
```

### Validating PowerShell Syntax

```powershell
# Check syntax without executing
Get-Command .\claude-key-switch.ps1 -Syntax

# Test script for errors (doesn't execute)
$null = [System.Management.Automation.PSParser]::Tokenize(
    (Get-Content .\claude-key-switch.ps1 -Raw), [ref]$null
)

# Run PSScriptAnalyzer (if installed)
Invoke-ScriptAnalyzer -Path .\claude-key-switch.ps1
Invoke-ScriptAnalyzer -Path .\Install-ClaudeKeySwitch.ps1

# Install PSScriptAnalyzer
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
```

### Manual Testing Workflow (PowerShell)

```powershell
# 1. Set up test environment variables
$env:CLAUDE_KEY_1 = 'sk-ant-api03-test-key-1'
$env:CLAUDE_KEY_2 = 'sk-ant-api03-test-key-2'
$env:CLAUDE_KEY_3 = 'sk-ant-api03-test-key-3'

# 2. Run the switcher
.\claude-key-switch.ps1

# 3. Verify the update in PowerShell profile
Get-Content $PROFILE | Select-String -Pattern "claude-key-switch" -Context 0,2

# 4. Check current index
Get-Content .key-index

# 5. Clean up test state
Remove-Item .key-index -Force -ErrorAction SilentlyContinue

# 6. Remove test environment variables
Remove-Item env:\CLAUDE_KEY_1, env:\CLAUDE_KEY_2, env:\CLAUDE_KEY_3
```

## Code Architecture

### File Structure

```
claude-key-switch/           # Main executable (POSIX sh)
install.sh                  # Interactive installer (POSIX sh)
claude-key-switch.ps1       # Main PowerShell script (Windows)
Install-ClaudeKeySwitch.ps1 # PowerShell installer (Windows)
.key-index                  # Persistent state: current key index (shared between POSIX and PowerShell)
.key-switch.lock/           # Directory-based lock for concurrent execution prevention
README.md                   # User documentation
CLAUDE.md                   # This file (development guide)
```

### Core Mechanisms

#### 1. Environment Variable Iteration

The tool discovers API keys by iterating through numbered environment variables:

```bash
CLAUDE_KEY_1='first-key'
CLAUDE_KEY_2='second-key'
CLAUDE_KEY_3='third-key'
# ... continues until a gap is found
```

**Critical Behavior**: The script stops at the first missing number. If you have `CLAUDE_KEY_1` and `CLAUDE_KEY_3` but not `CLAUDE_KEY_2`, only `CLAUDE_KEY_1` will be detected.

See `count_keys()` function in claude-key-switch:122-135.

#### 2. Atomic File Operations

- **Index Updates**: Uses `mktemp` + `mv` for atomic writes (claude-key-switch:113-119)
- **Shell Config Updates**: Uses `awk` to replace content between markers in-place (claude-key-switch:172-190)
- **Backups**: Created before any modification with timestamp suffix (claude-key-switch:165-166)

#### 3. Lock Mechanism (macOS-Compatible)

Uses `mkdir` for atomic locking instead of `flock` (not available on macOS):

```bash
mkdir "$LOCK_FILE" || error "Already running"
trap 'rmdir "$LOCK_FILE"' EXIT
```

See claude-key-switch:88-95. The lock is automatically released on exit via trap.

#### 4. Shell Config Markers

The tool uses marker comments to identify and update its section in shell config files:

```bash
# claude-key-switch START
export ANTHROPIC_AUTH_TOKEN='sk-ant-api03-xxx'
# claude-key-switch END
```

This allows idempotent updates without appending duplicates. See `update_shell_config()` in claude-key-switch:159-202.

#### 5. Modulo Arithmetic for Rotation

Key rotation uses modulo to wrap around: `next_index = (current_index + 1) % total_keys`

See claude-key-switch:215.

### Shell Detection Logic

The script auto-detects the user's shell and appropriate config file:

1. If `$ZSH_VERSION` is set → uses `~/.zshrc`
2. Otherwise checks for `~/.bash_profile` (macOS standard)
3. Falls back to `~/.bashrc`

See `detect_shell_config()` in claude-key-switch:145-157.

## Important Implementation Notes

### Working with Shell Scripts

1. **POSIX Compliance**: Do not use bash-specific features (`[[`, `$((..))` is OK but bashisms like `[[ ]]` are not)
2. **Variable Evaluation**: Uses `eval` for dynamic variable names (e.g., `eval "echo \"\${${var_name}}\""`)
3. **String Quoting**: Single quotes in exports prevent variable expansion: `export VAR='$VALUE'` (not `export VAR="$VALUE"`)
4. **Error Handling**: Uses `set -e` to exit on errors, combined with explicit error checking

### Working with PowerShell Scripts

1. **PowerShell Version**: Requires PowerShell 5.1+ (`#Requires -Version 5.1` at top of script)
2. **Parameter Parsing**: Use `[CmdletBinding()]` and `param()` blocks for proper cmdlet behavior
3. **Approved Verbs**: Follow PowerShell naming conventions (`Get-`, `Set-`, `New-`, `Remove-`, not `Fetch-` or `Create-`)
4. **Error Handling**: Use `try/catch/finally` blocks instead of trap, with `finally` for cleanup (lock release)
5. **Path Handling**: Always use `Join-Path` for constructing paths, never string concatenation with `\` or `/`
6. **Script Location**: Use `$PSScriptRoot` to get script directory (similar to `dirname "$0"` in POSIX)
7. **Environment Variables**: Use `[Environment]::GetEnvironmentVariable($name, "Process")` for reliable access
8. **File Encoding**: Always specify `-Encoding UTF8` when writing files to ensure consistency
9. **Atomic Operations**: Use temp file + `Move-Item -Force` pattern (similar to POSIX `mktemp` + `mv`)
10. **Profile Detection**: Use `$PROFILE` automatic variable which resolves to correct path for current PowerShell version

### PowerShell-Specific Patterns

**Directory-Based Locking:**
```powershell
$lockDir = Join-Path $scriptDir ".key-switch.lock"
try {
    New-Item -Path $lockDir -ItemType Directory -ErrorAction Stop | Out-Null
} catch {
    Write-ErrorMessage "Script is already running."
}

try {
    # Main script logic
} finally {
    Remove-Item -Path $lockDir -Force -ErrorAction SilentlyContinue
}
```

**Atomic File Write:**
```powershell
$tempFile = [System.IO.Path]::GetTempFileName()
try {
    Set-Content -Path $tempFile -Value $newIndex -NoNewline -ErrorAction Stop
    Move-Item -Path $tempFile -Destination $indexFile -Force -ErrorAction Stop
} catch {
    if (Test-Path $tempFile) {
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
    }
    throw
}
```

**Environment Variable Iteration:**
```powershell
function Count-Keys {
    $count = 0
    $i = 1

    while ($true) {
        $varName = "$script:KeyPrefix$i"
        $val = [Environment]::GetEnvironmentVariable($varName, "Process")

        if ([string]::IsNullOrEmpty($val)) {
            break
        }

        $count++
        $i++
    }

    return $count
}
```

**Marker-Based Config Updates:**
```powershell
$lines = Get-Content -Path $profilePath
$newLines = @()
$inSection = $false

foreach ($line in $lines) {
    if ($line -match [regex]::Escape($markerStart)) {
        $newLines += $line
        $newLines += $exportLine
        $inSection = $true
    }
    elseif ($line -match [regex]::Escape($markerEnd)) {
        $newLines += $line
        $inSection = $false
    }
    elseif (-not $inSection) {
        $newLines += $line
    }
}

# Atomic write
$tempFile = [System.IO.Path]::GetTempFileName()
$newLines | Set-Content -Path $tempFile -Encoding UTF8
Move-Item -Path $tempFile -Destination $profilePath -Force
```

### Security Considerations

**POSIX (macOS/Linux):**
- Environment variables are stored in shell config files (`~/.zshrc`, `~/.bash_profile`)
- These files should have `600` permissions (user read/write only)

**PowerShell (Windows):**
- Environment variables are stored in PowerShell profile (`$PROFILE`)
- Profile files inherit user-only permissions by default on Windows

**Both Platforms:**
- State files (`.key-index`, `.key-switch.lock`) are excluded from git via `.gitignore`
- Backups are created with restrictive permissions inherited from the original file
- Keys are never stored in files within the repository

### Testing Edge Cases

When modifying the code, ensure these edge cases still work:

**All Platforms:**
1. **Single key**: Should work (stays on same key)
2. **No keys**: Should error with helpful message
3. **Corrupted `.key-index`**: Should auto-reset to index -1 (becomes 0 on next run)
4. **Concurrent execution**: Second instance should fail with lock error
5. **Last key → first key**: Wrap-around should work seamlessly
6. **Missing shell config**: Should error with clear instructions
7. **Keys added/removed dynamically**: Should detect count changes

**Windows-Specific (PowerShell):**
8. **Execution Policy**: Script should provide helpful error if blocked by execution policy
9. **Profile doesn't exist**: Should auto-create directory structure and profile file
10. **Multiple PowerShell versions**: Should work with both 5.1 and 7+, detecting correct profile
11. **Line ending compatibility**: `.key-index` should work correctly with both CRLF and LF

### Modifying Configuration Variables

**POSIX (claude-key-switch:8-15):**
- `KEY_PREFIX="CLAUDE_KEY_"` - Environment variable prefix for keys
- `ENV_VAR_NAME="ANTHROPIC_AUTH_TOKEN"` - Target variable to set in shell config
- `MARKER_START` / `MARKER_END` - Shell config section markers

**PowerShell (claude-key-switch.ps1:37-43):**
- `$script:KeyPrefix = "CLAUDE_KEY_"` - Environment variable prefix for keys
- `$script:EnvVarName = "ANTHROPIC_AUTH_TOKEN"` - Target variable to set in profile
- `$script:MarkerStart` / `$script:MarkerEnd` - Profile section markers

**Note:** Keep these constants synchronized between POSIX and PowerShell versions for cross-platform compatibility.

## Common Development Patterns

### Adding New Features to the Main Script

**POSIX:**
1. Keep POSIX compliance - test with `sh -n claude-key-switch`
2. Follow existing patterns for atomicity (use temp files + `mv`)
3. Add error handling with descriptive messages using `error()` helper
4. Update help text in `show_help()` if adding new options
5. Consider concurrent execution safety (lock mechanism)

**PowerShell:**
1. Maintain PowerShell 5.1+ compatibility - test with `Get-Command .\claude-key-switch.ps1`
2. Follow existing patterns for atomicity (use temp files + `Move-Item -Force`)
3. Add error handling with `try/catch/finally` and `Write-ErrorMessage`
4. Update help text in comment-based help block if adding new parameters
5. Consider concurrent execution safety (directory-based locking with `try/finally`)

### Modifying the Installer

**POSIX:**
1. The installer uses interactive prompts - maintain the step-by-step flow
2. Use color helpers (`print_success`, `print_error`, etc.) for consistency
3. Always create backups before modifying user files
4. Validate user input (see key validation at install.sh:150-157)

**PowerShell:**
1. Maintain the same interactive step-by-step flow as POSIX version
2. Use helper functions (`Write-Success`, `Write-ErrorMessage`, etc.) for consistency
3. Always create timestamped backups before modifying user files
4. Validate user input (see key validation in `Get-ApiKeys` function)

### Debugging Tips

**POSIX:**
```bash
# Enable shell debugging
sh -x ./claude-key-switch

# Check what keys are detected
env | grep CLAUDE_KEY_

# Verify current state
cat .key-index

# Check if markers exist in shell config
grep "claude-key-switch" ~/.zshrc
```

**PowerShell:**
```powershell
# Enable verbose output
.\claude-key-switch.ps1 -Verbose

# Enable debug output
$DebugPreference = "Continue"
.\claude-key-switch.ps1

# Check what environment variables are set
Get-ChildItem env: | Where-Object Name -like "CLAUDE_KEY_*"

# Verify current state
Get-Content .key-index

# Check if markers exist in profile
Select-String -Path $PROFILE -Pattern "claude-key-switch"
```
