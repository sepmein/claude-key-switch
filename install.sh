#!/bin/sh

# claude-key-switch installer
# Interactive setup script for API key management

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SWITCH_SCRIPT="$SCRIPT_DIR/claude-key-switch"

# Helper functions
print_header() {
    printf "\n${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    printf "${CYAN}${BOLD}  $1${NC}\n"
    printf "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n\n"
}

print_success() {
    printf "${GREEN}✓ %s${NC}\n" "$1"
}

print_error() {
    printf "${RED}✗ %s${NC}\n" "$1" >&2
}

print_info() {
    printf "${BLUE}ℹ %s${NC}\n" "$1"
}

print_warning() {
    printf "${YELLOW}⚠ %s${NC}\n" "$1"
}

prompt() {
    printf "${YELLOW}? ${NC}${BOLD}%s${NC} " "$1"
}

error_exit() {
    print_error "$1"
    exit 1
}

# Welcome message
clear
cat << "EOF"
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

EOF

printf "${CYAN}${BOLD}Installation & Setup${NC}\n\n"
print_info "This script will help you set up claude-key-switch"
print_info "It will add API keys to your shell configuration"
printf "\n"

# Check if main script exists
if [ ! -f "$SWITCH_SCRIPT" ]; then
    error_exit "claude-key-switch script not found in $SCRIPT_DIR"
fi

# Step 1: Choose shell
print_header "Step 1: Choose Your Shell"

print_info "Which shell do you want to configure?"
printf "\n"
printf "  ${BOLD}1)${NC} zsh    (${GREEN}~/.zshrc${NC})\n"
printf "  ${BOLD}2)${NC} bash   (${GREEN}~/.bash_profile${NC})\n"
printf "\n"

while true; do
    prompt "Enter your choice [1 or 2]:"
    read -r SHELL_CHOICE

    case "$SHELL_CHOICE" in
        1)
            SHELL_TYPE="zsh"
            CONFIG_FILE="$HOME/.zshrc"
            break
            ;;
        2)
            SHELL_TYPE="bash"
            # Prefer .bash_profile on macOS
            if [ "$(uname)" = "Darwin" ]; then
                CONFIG_FILE="$HOME/.bash_profile"
            else
                CONFIG_FILE="$HOME/.bashrc"
            fi
            break
            ;;
        *)
            print_warning "Invalid choice. Please enter 1 or 2."
            ;;
    esac
done

print_success "Selected: $SHELL_TYPE ($CONFIG_FILE)"

# Create config file if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    print_warning "Config file doesn't exist. Creating $CONFIG_FILE"
    touch "$CONFIG_FILE"
    print_success "Created $CONFIG_FILE"
fi

# Step 2: Enter API keys
print_header "Step 2: Add Your API Keys"

print_info "Enter your API keys (one at a time)"
print_info "Press Enter with empty input when done"
printf "\n"

KEY_COUNT=0
KEYS_TO_ADD=""

while true; do
    KEY_NUM=$((KEY_COUNT + 1))
    prompt "API Key #${KEY_NUM} (or press Enter to finish):"
    read -r API_KEY

    # Check if user wants to finish
    if [ -z "$API_KEY" ]; then
        if [ "$KEY_COUNT" -eq 0 ]; then
            print_warning "You must enter at least one API key"
            continue
        else
            break
        fi
    fi

    # Basic validation
    if [ ${#API_KEY} -lt 20 ]; then
        print_warning "API key seems too short. Are you sure it's correct?"
        prompt "Continue anyway? [y/N]:"
        read -r CONFIRM
        if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
            continue
        fi
    fi

    # Add to list
    KEYS_TO_ADD="${KEYS_TO_ADD}export CLAUDE_KEY_${KEY_NUM}='${API_KEY}'
"
    KEY_COUNT=$((KEY_COUNT + 1))
    print_success "Added key #${KEY_NUM}"
done

if [ "$KEY_COUNT" -eq 0 ]; then
    error_exit "No API keys entered. Aborting installation."
fi

printf "\n"
print_success "Total keys to add: $KEY_COUNT"

# Step 3: Confirm and install
print_header "Step 3: Review & Confirm"

printf "${BOLD}Summary:${NC}\n"
printf "  • Shell: ${GREEN}$SHELL_TYPE${NC}\n"
printf "  • Config file: ${GREEN}$CONFIG_FILE${NC}\n"
printf "  • Number of keys: ${GREEN}$KEY_COUNT${NC}\n"
printf "\n"

print_warning "This will add the following to your $CONFIG_FILE:"
printf "\n${CYAN}"
cat << EOF
# claude-key-switch - API Keys
# Added by installer on $(date)
$KEYS_TO_ADD
EOF
printf "${NC}\n"

prompt "Proceed with installation? [Y/n]:"
read -r CONFIRM

if [ "$CONFIRM" = "n" ] || [ "$CONFIRM" = "N" ]; then
    print_error "Installation cancelled by user"
    exit 0
fi

# Step 4: Install
print_header "Step 4: Installing"

# Make main script executable
if [ ! -x "$SWITCH_SCRIPT" ]; then
    chmod +x "$SWITCH_SCRIPT"
    print_success "Made claude-key-switch executable"
fi

# Backup existing config
BACKUP_FILE="${CONFIG_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
cp "$CONFIG_FILE" "$BACKUP_FILE"
print_success "Created backup: $BACKUP_FILE"

# Check if keys already exist
if grep -q "# claude-key-switch - API Keys" "$CONFIG_FILE" 2>/dev/null; then
    print_warning "Found existing claude-key-switch keys in $CONFIG_FILE"
    prompt "Replace existing keys? [y/N]:"
    read -r REPLACE

    if [ "$REPLACE" = "y" ] || [ "$REPLACE" = "Y" ]; then
        # Remove old keys section
        TMP_FILE=$(mktemp)
        awk '
            /# claude-key-switch - API Keys/ { skip=1 }
            skip && /^export CLAUDE_KEY_[0-9]+/ { next }
            skip && /^$/ { skip=0; next }
            !skip { print }
        ' "$CONFIG_FILE" > "$TMP_FILE"
        mv "$TMP_FILE" "$CONFIG_FILE"
        print_success "Removed old keys"
    else
        print_warning "Keeping existing keys. New keys will be appended."
    fi
fi

# Add keys to config file
{
    echo ""
    echo "# claude-key-switch - API Keys"
    echo "# Added by installer on $(date)"
    echo "$KEYS_TO_ADD"
} >> "$CONFIG_FILE"

print_success "Added API keys to $CONFIG_FILE"

# Add convenient alias
if ! grep -q "alias switch-key=" "$CONFIG_FILE" 2>/dev/null; then
    {
        echo "# claude-key-switch - Convenient alias"
        echo "alias switch-key='$SWITCH_SCRIPT && source $CONFIG_FILE'"
    } >> "$CONFIG_FILE"
    print_success "Added 'switch-key' alias"
fi

# Step 5: Completion
print_header "Installation Complete! 🎉"

printf "${GREEN}${BOLD}✓ Successfully installed claude-key-switch${NC}\n\n"

printf "${BOLD}Next Steps:${NC}\n\n"
printf "  ${BOLD}1.${NC} Reload your shell configuration:\n"
printf "     ${CYAN}source $CONFIG_FILE${NC}\n\n"

printf "  ${BOLD}2.${NC} Test the installation:\n"
printf "     ${CYAN}$SWITCH_SCRIPT${NC}\n"
printf "     or use the alias:\n"
printf "     ${CYAN}switch-key${NC}\n\n"

printf "  ${BOLD}3.${NC} View help:\n"
printf "     ${CYAN}$SWITCH_SCRIPT --help${NC}\n\n"

printf "${BOLD}Quick Reference:${NC}\n"
printf "  • Your keys are stored as: ${GREEN}CLAUDE_KEY_1, CLAUDE_KEY_2, ...${NC}\n"
printf "  • Each run switches to the next key automatically\n"
printf "  • Keys wrap around (last → first)\n"
printf "  • Backup created at: ${YELLOW}$BACKUP_FILE${NC}\n\n"

printf "${BOLD}To add more keys later:${NC}\n"
printf "  Edit ${GREEN}$CONFIG_FILE${NC} and add:\n"
printf "  ${CYAN}export CLAUDE_KEY_${KEY_COUNT}_plus_1='your-new-key'${NC}\n\n"

print_info "Configuration file: $CONFIG_FILE"
print_info "Script location: $SWITCH_SCRIPT"

printf "\n${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
printf "${GREEN}${BOLD}Happy switching! 🔄${NC}\n"
printf "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n\n"
