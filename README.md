# claude-key-switch

A simple macOS shell tool to rotate through multiple API keys sequentially using environment variables.

## Features

- 🔄 Sequential rotation through multiple API keys
- ⚡ Automatic shell configuration updates
- 🛡️ Safe atomic writes with backups
- 🔒 Concurrent execution protection
- 🌍 Environment variable-based storage (secure & clean)

## Quick Start

### Installation (Recommended)

Run the interactive installer:

```bash
./install.sh
```

The installer will:
- Let you choose your shell (bash or zsh)
- Guide you through adding API keys
- Set up everything automatically
- Create a convenient `switch-key` alias

### Manual Setup

Alternatively, add API keys manually to your shell configuration (~/.zshrc or ~/.bash_profile):

```bash
# Add to ~/.zshrc (for zsh) or ~/.bash_profile (for bash)
export CLAUDE_KEY_1='sk-ant-api03-xxx-your-first-key'
export CLAUDE_KEY_2='sk-ant-api03-yyy-your-second-key'
export CLAUDE_KEY_3='sk-ant-api03-zzz-your-third-key'
```

Then reload your shell:

```bash
source ~/.zshrc  # or source ~/.bash_profile
```

### Usage

```bash
./claude-key-switch
```

Each time you run it, the script switches to the next key and updates your active `ANTHROPIC_AUTH_TOKEN`.

If you used the installer, you can also use the convenient alias:

```bash
switch-key  # Switches and applies changes automatically
```

Otherwise, apply changes manually:

```bash
# For zsh
source ~/.zshrc

# For bash
source ~/.bash_profile
```

Or simply restart your terminal.

## How It Works

1. **Reads** environment variables `CLAUDE_KEY_1`, `CLAUDE_KEY_2`, `CLAUDE_KEY_3`, etc.
2. **Calculates** next key using modulo arithmetic (wraps around)
3. **Updates** `ANTHROPIC_AUTH_TOKEN` in your shell config
4. **Saves** current index for next run
5. **Creates** backup of your config file

The script uses marker comments in your shell config:

```bash
# claude-key-switch START
export ANTHROPIC_AUTH_TOKEN='sk-ant-api03-xxx'
# claude-key-switch END
```

This allows safe, idempotent updates without duplicating entries.

## File Structure

```
claude-key-switch/
├── claude-key-switch    # Main executable script
├── install.sh           # Interactive installer
├── .key-index           # Current key index (auto-managed)
└── README.md            # This file
```

## Usage Examples

### Basic Usage

```bash
# Switch to next key
./claude-key-switch

# Output:
# ✓ Switched to key 2 of 3
# Updated: /Users/you/.zshrc
# Run 'source /Users/you/.zshrc' or restart your terminal to apply changes
```

### Show Help

```bash
./claude-key-switch --help
```

### Check Version

```bash
./claude-key-switch --version
```

## Configuration

### Environment Variable Names

The script looks for keys in variables named:
- `CLAUDE_KEY_1`
- `CLAUDE_KEY_2`
- `CLAUDE_KEY_3`
- ... and so on

To change the prefix, edit the `KEY_PREFIX` variable in the script:

```bash
KEY_PREFIX="YOUR_PREFIX_"  # Will look for YOUR_PREFIX_1, YOUR_PREFIX_2, etc.
```

### Target Environment Variable

By default, the script sets `ANTHROPIC_AUTH_TOKEN`. To change this, edit the `ENV_VAR_NAME` variable in the script:

```bash
ENV_VAR_NAME="YOUR_CUSTOM_VAR_NAME"
```

### Shell Detection

The script automatically detects your shell:
- **zsh**: Updates `~/.zshrc`
- **bash**: Updates `~/.bash_profile` (or `~/.bashrc` as fallback)

## Edge Cases Handled

| Scenario | Behavior |
|----------|----------|
| No environment variables set | Error with setup instructions |
| Single key | Works (stays on same key) |
| Corrupted `.key-index` | Auto-resets to first key |
| Concurrent runs | Blocks with lock directory |
| Last key → first key | Automatic wrap-around |

## Security Best Practices

### 1. Environment Variables vs Files

✅ **Advantages of using environment variables:**
- No files containing secrets to accidentally commit
- Standard practice for credentials
- Easy to integrate with secrets management tools
- Can be set per-shell session for isolation

### 2. Secure Your Shell Config

Your shell config now contains your API keys, so protect it:

```bash
# Ensure only you can read your shell config
chmod 600 ~/.zshrc  # or ~/.bash_profile
```

### 3. Use Different Keys

Set up different keys for different purposes:
- `CLAUDE_KEY_1` - Production
- `CLAUDE_KEY_2` - Development
- `CLAUDE_KEY_3` - Testing

### 4. Backup Management

The script creates timestamped backups of your shell config:

```bash
~/.zshrc.backup.1735171200
~/.zshrc.backup.1735257600
```

You can safely delete old backups:

```bash
rm ~/.zshrc.backup.*
```

### 5. Git Safety

If using version control in this directory, the `.gitignore` already excludes state files:

```
.key-index
.key-switch.lock
```

## Troubleshooting

### "No API keys found"

Set your environment variables and reload your shell:

```bash
export CLAUDE_KEY_1='sk-ant-api03-your-key'
source ~/.zshrc  # or ~/.bash_profile
./claude-key-switch
```

### "Script is already running"

Another instance is active. Wait for it to complete or remove the lock:

```bash
rmdir .key-switch.lock
```

### "No shell config file found"

Create one manually:

```bash
# For zsh
touch ~/.zshrc

# For bash
touch ~/.bash_profile
```

### Changes not applied

Remember to source your config or restart terminal:

```bash
source ~/.zshrc  # or ~/.bash_profile
```

### Verify Current Setup

Check which keys are available:

```bash
env | grep CLAUDE_KEY_
```

Check current key index:

```bash
cat .key-index
```

## Advanced Usage

### Use with Aliases

Add to your shell config:

```bash
alias switch-key='/path/to/claude-key-switch/claude-key-switch && source ~/.zshrc'
```

Then simply run:

```bash
switch-key  # Switches and applies immediately
```

### Check Current Active Key

Look for the markers in your shell config:

```bash
grep -A 1 "claude-key-switch START" ~/.zshrc
```

### Reset to First Key

Delete the index file:

```bash
rm .key-index
./claude-key-switch  # Will start from first key
```

### Load Keys from Secrets Manager

You can source keys from external tools:

```bash
# Example: Load from 1Password
export CLAUDE_KEY_1=$(op read "op://Private/Claude API 1/credential")
export CLAUDE_KEY_2=$(op read "op://Private/Claude API 2/credential")
export CLAUDE_KEY_3=$(op read "op://Private/Claude API 3/credential")
```

### Add Keys Without Restart

You can add new keys dynamically:

```bash
# Add a new key
export CLAUDE_KEY_4='sk-ant-api03-new-key'

# The script will automatically detect it
./claude-key-switch
```

## Migration from keys.txt

If you were using the file-based version, migrate like this:

```bash
# Read your old keys.txt and create exports
i=1
while IFS= read -r key; do
  # Skip comments and empty lines
  if [[ ! "$key" =~ ^# ]] && [[ -n "$key" ]]; then
    echo "export CLAUDE_KEY_${i}='${key}'"
    i=$((i + 1))
  fi
done < keys.txt

# Then manually add the exports to your ~/.zshrc or ~/.bash_profile
```

## Technical Details

### POSIX Compliance

The script uses `/bin/sh` for maximum compatibility. It avoids bash-specific features and works on all macOS versions.

### Atomic Operations

- **Index updates**: Uses temp file + `mv` for atomic writes
- **Config updates**: Uses `awk` for in-place marker replacement
- **Backups**: Created before any modification

### Lock Mechanism

Uses `mkdir` (atomic on POSIX) instead of `flock` (not available on macOS):

```bash
mkdir "$LOCK_FILE" || error "Already running"
trap 'rmdir "$LOCK_FILE"' EXIT
```

### Environment Variable Iteration

The script iterates through numbered environment variables until it finds a gap:

```bash
i=1
while [ -n "${CLAUDE_KEY_${i}}" ]; do
  count=$((count + 1))
  i=$((i + 1))
done
```

## FAQ

**Q: Can I skip key numbers?**
A: No. The script stops at the first missing number. If you have KEY_1 and KEY_3 but not KEY_2, only KEY_1 will be detected.

**Q: How many keys can I have?**
A: No practical limit. You can have CLAUDE_KEY_1 through CLAUDE_KEY_100 or more.

**Q: Does it work with bash and zsh?**
A: Yes, it auto-detects your shell and updates the appropriate config file.

**Q: Can I manually set which key to use?**
A: Edit `.key-index` to the desired index (0-based). Next run will increment from there.

**Q: Will it break my shell config?**
A: No. It creates backups and uses markers to isolate its changes.

**Q: Can I use this for non-Anthropic APIs?**
A: Yes! Just change `ENV_VAR_NAME` in the script to match your API's environment variable.

## License

MIT License - Free to use and modify

## Contributing

Issues and improvements welcome! This is a simple tool designed to stay simple.

---

**Created for**: Managing multiple Anthropic API keys via environment variables
**Platform**: macOS
**Shell**: POSIX sh (compatible with bash and zsh)
