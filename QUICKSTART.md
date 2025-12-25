# Claude Key Switch - Quick Reference

## 🚀 Installation

```bash
./install.sh
```

Follow the interactive prompts to:
- Choose shell (bash/zsh)
- Add API keys
- Automatic setup

## 📖 Usage

### Switch to Next Key
```bash
./claude-key-switch
```

### Use Convenient Alias (if installed via install.sh)
```bash
switch-key
```

### Check Version
```bash
./claude-key-switch --version
```

### Get Help
```bash
./claude-key-switch --help
```

## 🔧 Manual Configuration

### Add Keys to Shell Config (~/.zshrc or ~/.bash_profile)
```bash
export CLAUDE_KEY_1='sk-ant-api03-xxx-first-key'
export CLAUDE_KEY_2='sk-ant-api03-yyy-second-key'
export CLAUDE_KEY_3='sk-ant-api03-zzz-third-key'
```

### Reload Shell
```bash
source ~/.zshrc  # or source ~/.bash_profile
```

## 🎯 How It Works

1. Reads `CLAUDE_KEY_1`, `CLAUDE_KEY_2`, etc. from environment
2. Rotates sequentially: 1 → 2 → 3 → 1 (automatic wrap-around)
3. Updates `ANTHROPIC_AUTH_TOKEN` in shell config
4. Creates automatic backups

## 📁 File Structure

```
claude-key-switch/
├── claude-key-switch    # Main script
├── install.sh           # Interactive installer
├── .key-index           # Current position (auto-managed)
├── .gitignore          # Protects state files
└── README.md           # Full documentation
```

## 🔍 Troubleshooting

### Check Available Keys
```bash
env | grep CLAUDE_KEY_
```

### Check Current Index
```bash
cat .key-index
```

### Reset to First Key
```bash
rm .key-index
```

### View Active Key
```bash
grep -A 1 "claude-key-switch START" ~/.zshrc
```

## ⚙️ Customization

### Change Key Prefix
Edit `KEY_PREFIX` in `claude-key-switch`:
```bash
KEY_PREFIX="MY_API_KEY_"  # Will look for MY_API_KEY_1, MY_API_KEY_2, etc.
```

### Change Target Variable
Edit `ENV_VAR_NAME` in `claude-key-switch`:
```bash
ENV_VAR_NAME="MY_CUSTOM_TOKEN"
```

## 🛡️ Security Tips

1. **Protect your shell config:**
   ```bash
   chmod 600 ~/.zshrc
   ```

2. **Never commit shell config with real keys**

3. **Use different keys for different environments:**
   - CLAUDE_KEY_1 → Production
   - CLAUDE_KEY_2 → Development
   - CLAUDE_KEY_3 → Testing

## 📝 Notes

- Keys must be numbered sequentially (no gaps)
- Script stops at first missing number
- Backups created automatically: `~/.zshrc.backup.TIMESTAMP`
- Lock prevents concurrent execution
- Works on macOS (zsh and bash)
