# claude-key-switch

A simple macOS shell tool for rotating through multiple API keys sequentially using environment variables.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Shell: POSIX](https://img.shields.io/badge/Shell-POSIX-green.svg)](https://en.wikipedia.org/wiki/POSIX)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)](https://www.apple.com/macos/)

## 🎯 Features

- **🔄 Sequential Rotation** - Automatic rotation through multiple API keys with wrap-around
- **⚡ Interactive Installer** - Guided setup with shell selection (bash/zsh)
- **🔒 Environment-Based Storage** - Secure credential management without files
- **🛡️ Atomic Operations** - Safe updates with automatic backups
- **🚀 Concurrent Protection** - Lock mechanism prevents race conditions
- **📦 Zero Dependencies** - Pure POSIX shell script

---

## 🚀 Quick Start

### Installation

Run the interactive installer:

```bash
./install.sh
```

The installer will:

- Let you choose your shell (bash or zsh)
- Guide you through adding API keys
- Set up everything automatically
- Create a convenient `switch-key` alias

### Usage

```bash
# Using the alias (recommended)
switch-key

# Or run the script directly
./claude-key-switch

# View help
./claude-key-switch --help
```

That's it! Each run switches to the next key automatically.

---

## 📖 Table of Contents

- [Installation](#installation)
- [Usage Examples](#usage-examples)
- [How It Works](#how-it-works)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)
- [Security Best Practices](#security-best-practices)
- [Technical Details](#technical-details)
- [FAQ](#faq)
- [Contributing](#contributing)

---

## 📦 Installation

### Option 1: Interactive Installer (Recommended)

```bash
./install.sh
```

**Demo:**

```
   ______ __                __           __ __
  / ____// /____ _ __  __ ____/ /___       / //_/___   __  __
 / /    / // __ `// / / // __  // _ \     / ,<  / _ \ / / / /
/ /___ / // /_/ // /_/ // /_/ //  __/    / /| |/  __// /_/ /
\____//_/ \__,_/ \__,_/ \__,_/ \___/    /_/ |_|\___/ \__, /
                                                    /____/

? Enter your choice [1 or 2]: 1
✓ Selected: zsh (/Users/you/.zshrc)

? API Key #1: sk-ant-api03-xxx-production
✓ Added key #1
? API Key #2: sk-ant-api03-yyy-development
✓ Added key #2
? API Key #3: [Enter to finish]

✓ Successfully installed claude-key-switch
```

### Option 2: Manual Setup

Add API keys to your shell configuration:

```bash
# For zsh users: Add to ~/.zshrc
# For bash users: Add to ~/.bash_profile

export CLAUDE_KEY_1='sk-ant-api03-xxx-your-first-key'
export CLAUDE_KEY_2='sk-ant-api03-yyy-your-second-key'
export CLAUDE_KEY_3='sk-ant-api03-zzz-your-third-key'
```

Reload your shell:

```bash
source ~/.zshrc  # or source ~/.bash_profile
```

Make the script executable:

```bash
chmod +x claude-key-switch
```

---

## 🎬 Usage Examples

### Basic Usage

**First run - Switch to key 1:**
```bash
$ ./claude-key-switch
✓ Switched to key 1 of 3
Updated: /Users/you/.zshrc
Run 'source /Users/you/.zshrc' or restart your terminal to apply changes
```

**Second run - Switch to key 2:**
```bash
$ ./claude-key-switch
✓ Switched to key 2 of 3
Updated: /Users/you/.zshrc
```

**Third run - Switch to key 3:**
```bash
$ ./claude-key-switch
✓ Switched to key 3 of 3
Updated: /Users/you/.zshrc
```

**Fourth run - Wrap around to key 1:**
```bash
$ ./claude-key-switch
✓ Switched to key 1 of 3
Updated: /Users/you/.zshrc
```

### Using the Alias

If you used the installer:

```bash
switch-key  # Switches and applies changes automatically
```

### Checking Current State

**View available keys:**
```bash
$ env | grep CLAUDE_KEY_
CLAUDE_KEY_1=sk-ant-api03-xxx-production
CLAUDE_KEY_2=sk-ant-api03-yyy-development
CLAUDE_KEY_3=sk-ant-api03-zzz-testing
```

**View current index:**
```bash
$ cat .key-index
1
```

**View active key:**
```bash
$ grep -A 1 "claude-key-switch START" ~/.zshrc
# claude-key-switch START
export ANTHROPIC_AUTH_TOKEN='sk-ant-api03-yyy-development'
```

---

## ⚙️ How It Works

### The Process

1. **Reads** environment variables: `CLAUDE_KEY_1`, `CLAUDE_KEY_2`, `CLAUDE_KEY_3`, etc.
2. **Calculates** next key using modulo arithmetic (automatic wrap-around)
3. **Updates** `ANTHROPIC_AUTH_TOKEN` in your shell config file
4. **Saves** current index to `.key-index` for next run
5. **Creates** timestamped backup of your config file

### Shell Configuration Markers

The script uses marker comments to identify its section:

```bash
# claude-key-switch START
export ANTHROPIC_AUTH_TOKEN='sk-ant-api03-xxx'
# claude-key-switch END
```

This enables **idempotent updates** - the script can run multiple times without creating duplicates.

### File Structure

```
claude-key-switch/
├── claude-key-switch     # Main executable (POSIX shell script)
├── install.sh            # Interactive installer
├── .key-index            # Current key index (auto-managed)
├── .gitignore           # Protects state files from commits
└── README.md            # This file
```

### Architecture Highlights

- **POSIX Compliance**: Uses `/bin/sh` for maximum compatibility
- **Atomic Operations**: Temp file + `mv` pattern prevents corruption
- **Lock Mechanism**: Uses `mkdir` (atomic on POSIX) for concurrent protection
- **Environment Variables**: Secure storage without files containing secrets

---

## 🔧 Configuration

### Adding More Keys

Add new environment variables to your shell config:

```bash
# Add to ~/.zshrc or ~/.bash_profile
export CLAUDE_KEY_4='sk-ant-api03-new-key'
```

The script automatically detects the new key.

### Customizing Variable Names

Edit the constants in the `claude-key-switch` script:

```bash
KEY_PREFIX="CLAUDE_KEY_"           # Change to: YOUR_PREFIX_
ENV_VAR_NAME="ANTHROPIC_AUTH_TOKEN"  # Change to: YOUR_VAR_NAME
```

### Shell Detection

The script automatically detects your shell:
- **zsh**: Updates `~/.zshrc`
- **bash**: Updates `~/.bash_profile` (or `~/.bashrc` as fallback)

---

## 🔍 Troubleshooting

### Error: "No API keys found"

**Solution:** Set your environment variables and reload your shell:

```bash
export CLAUDE_KEY_1='sk-ant-api03-your-key'
source ~/.zshrc  # or source ~/.bash_profile
./claude-key-switch
```

### Error: "Script is already running"

**Solution:** Another instance is active. Wait or remove the lock:

```bash
rmdir .key-switch.lock
```

### Error: "No shell config file found"

**Solution:** Create one manually:

```bash
# For zsh
touch ~/.zshrc

# For bash
touch ~/.bash_profile
```

### Changes Not Applied

**Solution:** Remember to source your config or restart terminal:

```bash
source ~/.zshrc  # or source ~/.bash_profile
```

### Verify Setup

```bash
# Check available keys
env | grep CLAUDE_KEY_

# Check current index
cat .key-index

# Check shell config
grep "claude-key-switch" ~/.zshrc
```

---

## 🚀 Advanced Usage

### Create Convenient Alias

Add to your shell config:

```bash
alias switch-key='/path/to/claude-key-switch/claude-key-switch && source ~/.zshrc'
```

Then simply run:

```bash
switch-key  # Switches and applies immediately
```

### Reset to First Key

```bash
rm .key-index
./claude-key-switch  # Will start from first key
```

### Load Keys from Secrets Manager

Example with 1Password:

```bash
export CLAUDE_KEY_1=$(op read "op://Private/Claude API 1/credential")
export CLAUDE_KEY_2=$(op read "op://Private/Claude API 2/credential")
export CLAUDE_KEY_3=$(op read "op://Private/Claude API 3/credential")
```

### Integration with Git Hooks

```bash
#!/bin/sh
# .git/hooks/pre-push

# Switch to production key before pushing
/path/to/claude-key-switch
source ~/.zshrc
```

### Integration with Cron Jobs

```bash
# Switch keys every hour
0 * * * * /path/to/claude-key-switch
```

### Integration with CI/CD

```yaml
# .github/workflows/test.yml
steps:
  - name: Setup API keys
    run: |
      export CLAUDE_KEY_1="${{ secrets.CLAUDE_PROD }}"
      export CLAUDE_KEY_2="${{ secrets.CLAUDE_DEV }}"
      /path/to/claude-key-switch
```

### Add Keys Dynamically

```bash
# Add a new key without restart
export CLAUDE_KEY_4='sk-ant-api03-new-key'

# The script will automatically detect it
./claude-key-switch
```

---

## 🛡️ Security Best Practices

### 1. Environment Variables vs Files

**✅ Advantages of environment variables:**
- No files containing secrets to accidentally commit
- Standard practice for credentials
- Easy integration with secrets management tools
- Can be set per-shell session for isolation

### 2. Protect Your Shell Configuration

```bash
# Ensure only you can read your shell config
chmod 600 ~/.zshrc  # or ~/.bash_profile
```

### 3. Organize Keys by Purpose

```bash
export CLAUDE_KEY_1='sk-ant-api03-xxx'  # Production
export CLAUDE_KEY_2='sk-ant-api03-yyy'  # Development
export CLAUDE_KEY_3='sk-ant-api03-zzz'  # Testing
```

### 4. Backup Management

The script creates timestamped backups:

```bash
~/.zshrc.backup.1735171200
~/.zshrc.backup.1735257600
```

Clean up old backups periodically:

```bash
rm ~/.zshrc.backup.*
```

### 5. Git Safety

The `.gitignore` automatically excludes:
- `.key-index` (state file)
- `.key-switch.lock` (lock directory)
- `*.backup.*` (backup files)

---

## 🔬 Technical Details

### POSIX Compliance

The script uses `/bin/sh` for maximum compatibility. It avoids bash-specific features and works on all macOS versions.

### Atomic Operations

- **Index updates**: Uses temp file + `mv` for atomic writes
- **Config updates**: Uses `awk` for in-place marker replacement
- **Backups**: Created before any modification

### Lock Mechanism (macOS-Compatible)

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

**Important:** Keys must be numbered sequentially without gaps. If you have `KEY_1` and `KEY_3` but not `KEY_2`, only `KEY_1` will be detected.

### Edge Cases Handled

| Scenario | Behavior |
|----------|----------|
| No environment variables set | Error with setup instructions |
| Single key | Works (stays on same key) |
| Corrupted `.key-index` | Auto-resets to first key |
| Concurrent runs | Blocks with lock directory |
| Last key → first key | Automatic wrap-around |

---

## ❓ FAQ

**Q: Can I skip key numbers?**
A: No. The script stops at the first missing number. If you have `KEY_1` and `KEY_3` but not `KEY_2`, only `KEY_1` will be detected.

**Q: How many keys can I have?**
A: No practical limit. You can have `CLAUDE_KEY_1` through `CLAUDE_KEY_100` or more.

**Q: Does it work with both bash and zsh?**
A: Yes, it auto-detects your shell and updates the appropriate config file.

**Q: Can I manually set which key to use?**
A: Edit `.key-index` to the desired index (0-based). Next run will increment from there.

**Q: Will it break my shell config?**
A: No. It creates backups and uses markers to isolate its changes. All operations are atomic.

**Q: Can I use this for non-Anthropic APIs?**
A: Yes! Just change `ENV_VAR_NAME` in the script to match your API's environment variable.

**Q: What happens if I add or remove keys?**
A: The script automatically detects the current count of keys each time it runs.

**Q: Is it safe to run multiple times quickly?**
A: Yes. The lock mechanism prevents concurrent execution, ensuring safe operation.

---

## 📊 Project Metrics

| Metric | Value |
|--------|-------|
| **Language** | POSIX Shell |
| **Lines of Code** | ~400 |
| **Dependencies** | None |
| **Platform** | macOS |
| **Shell Support** | bash, zsh |
| **Script Size** | 6.1 KB (main), 8.1 KB (installer) |

---

## 🎓 Design Decisions

### Why Environment Variables?
- Industry standard for credentials
- No files with secrets to manage
- Easy integration with secrets managers
- Session-level isolation possible

### Why POSIX Shell?
- Maximum compatibility across macOS versions
- No external dependencies
- Available on all Unix systems
- Lightweight and fast

### Why Numbered Variables?
- Simple iteration logic
- Easy to add/remove keys
- Clear ordering
- Shell-friendly syntax

### Why Atomic Operations?
- Prevents corruption from interrupts
- Safe concurrent attempts (with locks)
- Reliable state management
- Professional-grade robustness

---

## 🔮 Potential Enhancements

Future improvements to consider:
- Add `--list` to show all keys (masked)
- Add `--jump N` to switch to specific key
- Add `--validate` to check key format
- Support for `.env` file loading
- Integration with 1Password/Vault
- Homebrew formula for easy installation

---

## 📄 License

MIT License - Free to use and modify

---

## 🤝 Contributing

Issues and improvements welcome! This is a simple tool designed to stay simple.

---

## 📚 Additional Resources

- [Anthropic API Documentation](https://docs.anthropic.com/)
- [POSIX Shell Specification](https://pubs.opengroup.org/onlinepubs/9699919799/)
- [Shell Script Best Practices](https://google.github.io/styleguide/shellguide.html)

---

**Created for:** Managing multiple Anthropic API keys via environment variables
**Platform:** macOS
**Shell:** POSIX sh (compatible with bash and zsh)
**Version:** 1.0.0

---

<div align="center">

### 🎉 Ready to get started?

```bash
./install.sh
```

**Happy switching! 🔄**

</div>
