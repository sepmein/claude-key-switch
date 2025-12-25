# Claude Key Switch - Demo

## Installation Demo

```bash
$ ./install.sh

   ______ __                __           __ __
  / ____// /____ _ __  __ ____/ /___       / //_/___   __  __
 / /    / // __ `// / / // __  // _ \     / ,<  / _ \ / / / /
/ /___ / // /_/ // /_/ // /_/ //  __/    / /| |/  __// /_/ /
\____//_/ \__,_/ \__,_/ \__,_/ \___/    /_/ |_|\___/ \__, /
                                                    /____/
   _____         _  __         __
  / ___/ _      __(_)/ /_ _____ / /_
  \__ \ | | /| / / // __// ___// __ \
 ___/ / | |/ |/ / // /_ / /__ / / / /
/____/  |__/|__/_/ \__/ \___//_/ /_/

Installation & Setup

ℹ This script will help you set up claude-key-switch
ℹ It will add API keys to your shell configuration

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Step 1: Choose Your Shell
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ Which shell do you want to configure?

  1) zsh    (~/.zshrc)
  2) bash   (~/.bash_profile)

? Enter your choice [1 or 2]: 1
✓ Selected: zsh (/Users/you/.zshrc)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Step 2: Add Your API Keys
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ Enter your API keys (one at a time)
ℹ Press Enter with empty input when done

? API Key #1 (or press Enter to finish): sk-ant-api03-xxx-production
✓ Added key #1
? API Key #2 (or press Enter to finish): sk-ant-api03-yyy-development
✓ Added key #2
? API Key #3 (or press Enter to finish): sk-ant-api03-zzz-testing
✓ Added key #3
? API Key #4 (or press Enter to finish): [Enter]

✓ Total keys to add: 3

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Step 3: Review & Confirm
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Summary:
  • Shell: zsh
  • Config file: /Users/you/.zshrc
  • Number of keys: 3

⚠ This will add the following to your /Users/you/.zshrc:

# claude-key-switch - API Keys
# Added by installer on Thu Dec 25 2025
export CLAUDE_KEY_1='sk-ant-api03-xxx-production'
export CLAUDE_KEY_2='sk-ant-api03-yyy-development'
export CLAUDE_KEY_3='sk-ant-api03-zzz-testing'

? Proceed with installation? [Y/n]: Y

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Step 4: Installing
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Made claude-key-switch executable
✓ Created backup: /Users/you/.zshrc.backup-20251225-163000
✓ Added API keys to /Users/you/.zshrc
✓ Added 'switch-key' alias

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Installation Complete! 🎉
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Successfully installed claude-key-switch
```

## Usage Demo

### First Run - Switch to Key 1

```bash
$ ./claude-key-switch
✓ Switched to key 1 of 3
Updated: /Users/you/.zshrc
Run 'source /Users/you/.zshrc' or restart your terminal to apply changes
```

### Second Run - Switch to Key 2

```bash
$ ./claude-key-switch
✓ Switched to key 2 of 3
Updated: /Users/you/.zshrc
Run 'source /Users/you/.zshrc' or restart your terminal to apply changes
```

### Third Run - Switch to Key 3

```bash
$ ./claude-key-switch
✓ Switched to key 3 of 3
Updated: /Users/you/.zshrc
Run 'source /Users/you/.zshrc' or restart your terminal to apply changes
```

### Fourth Run - Wrap Around to Key 1

```bash
$ ./claude-key-switch
✓ Switched to key 1 of 3
Updated: /Users/you/.zshrc
Run 'source /Users/you/.zshrc' or restart your terminal to apply changes
```

## Using the Alias

If you used the installer, you get a convenient alias:

```bash
$ switch-key
✓ Switched to key 2 of 3
Updated: /Users/you/.zshrc
Run 'source /Users/you/.zshrc' or restart your terminal to apply changes
```

## What Gets Added to Your Shell Config

```bash
# claude-key-switch - API Keys
# Added by installer on Thu Dec 25 2025
export CLAUDE_KEY_1='sk-ant-api03-xxx-production'
export CLAUDE_KEY_2='sk-ant-api03-yyy-development'
export CLAUDE_KEY_3='sk-ant-api03-zzz-testing'

# claude-key-switch - Convenient alias
alias switch-key='/path/to/claude-key-switch && source ~/.zshrc'

# ... (rest of your config)

# claude-key-switch START
export ANTHROPIC_AUTH_TOKEN='sk-ant-api03-xxx-production'
# claude-key-switch END
```

## Checking Current State

### View Available Keys

```bash
$ env | grep CLAUDE_KEY_
CLAUDE_KEY_1=sk-ant-api03-xxx-production
CLAUDE_KEY_2=sk-ant-api03-yyy-development
CLAUDE_KEY_3=sk-ant-api03-zzz-testing
```

### View Current Index

```bash
$ cat .key-index
1
```

This means the next run will switch to key #2 (0-indexed, so 1 = second key).

### View Active Key

```bash
$ grep -A 1 "claude-key-switch START" ~/.zshrc
# claude-key-switch START
export ANTHROPIC_AUTH_TOKEN='sk-ant-api03-yyy-development'
```

## Error Handling Demo

### No Keys Set

```bash
$ (unset CLAUDE_KEY_1 CLAUDE_KEY_2 CLAUDE_KEY_3 && ./claude-key-switch)
Error: No API keys found. Set environment variables:
  export CLAUDE_KEY_1='your-first-key'
  export CLAUDE_KEY_2='your-second-key'
```

### Concurrent Execution

```bash
$ ./claude-key-switch &
$ ./claude-key-switch
Error: Script is already running. Please wait for it to complete.
```

## Integration Examples

### With Git Hooks

```bash
#!/bin/sh
# .git/hooks/pre-push

# Switch to production key before pushing
/path/to/claude-key-switch
source ~/.zshrc
```

### With Cron Jobs

```bash
# Switch keys every hour
0 * * * * /path/to/claude-key-switch
```

### With CI/CD

```yaml
# .github/workflows/test.yml
steps:
  - name: Setup API keys
    run: |
      export CLAUDE_KEY_1="${{ secrets.CLAUDE_PROD }}"
      export CLAUDE_KEY_2="${{ secrets.CLAUDE_DEV }}"
      /path/to/claude-key-switch
```
