# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**claude-key-switch** is a POSIX-compliant shell tool for macOS that rotates through multiple Anthropic API keys sequentially. The tool reads keys from environment variables and updates the user's shell configuration file atomically.

### Core Architecture

The project consists of two main shell scripts:

1. **claude-key-switch** (main executable) - Performs the key rotation logic
2. **install.sh** - Interactive installer that sets up environment variables and shell configuration

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

## Code Architecture

### File Structure

```
claude-key-switch/        # Main executable (POSIX sh)
install.sh               # Interactive installer (POSIX sh)
.key-index              # Persistent state: current key index (0-based, auto-managed)
.key-switch.lock/       # Directory-based lock for concurrent execution prevention
README.md               # User documentation
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

### Security Considerations

- Environment variables are stored in shell config files (`~/.zshrc`, `~/.bash_profile`)
- These files should have `600` permissions (user read/write only)
- State files (`.key-index`, `.key-switch.lock`) are excluded from git via `.gitignore`
- Backups are created with restrictive permissions inherited from the original file

### Testing Edge Cases

When modifying the code, ensure these edge cases still work:

1. **Single key**: Should work (stays on same key)
2. **No keys**: Should error with helpful message
3. **Corrupted `.key-index`**: Should auto-reset to index -1 (becomes 0 on next run)
4. **Concurrent execution**: Second instance should fail with lock error
5. **Last key → first key**: Wrap-around should work seamlessly
6. **Missing shell config**: Should error with clear instructions
7. **Keys added/removed dynamically**: Should detect count changes

### Modifying Configuration Variables

Key configuration constants in claude-key-switch:8-15:

- `KEY_PREFIX="CLAUDE_KEY_"` - Environment variable prefix for keys
- `ENV_VAR_NAME="ANTHROPIC_AUTH_TOKEN"` - Target variable to set in shell config
- `MARKER_START` / `MARKER_END` - Shell config section markers

## Common Development Patterns

### Adding New Features to the Main Script

1. Keep POSIX compliance - test with `sh -n claude-key-switch`
2. Follow existing patterns for atomicity (use temp files + `mv`)
3. Add error handling with descriptive messages using `error()` helper
4. Update help text in `show_help()` if adding new options
5. Consider concurrent execution safety (lock mechanism)

### Modifying the Installer

1. The installer uses interactive prompts - maintain the step-by-step flow
2. Use color helpers (`print_success`, `print_error`, etc.) for consistency
3. Always create backups before modifying user files
4. Validate user input (see key validation at install.sh:150-157)

### Debugging Tips

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
