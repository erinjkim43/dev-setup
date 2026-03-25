#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${BOLD}${CYAN}=== $1 ===${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}>>>${NC} $1"
}

print_success() {
    echo -e "${GREEN}[ok]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[!!]${NC} $1"
}

print_error() {
    echo -e "${RED}[err]${NC} $1"
}

print_installed() {
    echo -e "${GREEN}[installed]${NC} $1"
}

print_skipped() {
    echo -e "${YELLOW}[skipped]${NC} $1"
}

# Check if a command exists
is_installed() {
    command -v "$1" >/dev/null 2>&1
}

# Install a package with the detected package manager, with already-installed check
pkg_install() {
    local name="$1"
    local cmd_check="${2:-$1}" # command to check, defaults to package name

    if is_installed "$cmd_check"; then
        print_installed "$name"
        return 0
    fi

    print_step "Installing $name..."
    case "$PACKAGE_MANAGER" in
        "brew")
            brew install "$name" || { print_warn "Failed to install $name"; return 1; }
            ;;
        "apt")
            sudo apt install -y "$name" || { print_warn "Failed to install $name"; return 1; }
            ;;
    esac
    print_success "$name installed"
}

# Install a brew cask (macOS only)
cask_install() {
    local name="$1"
    if [[ "$PACKAGE_MANAGER" != "brew" ]]; then
        print_warn "$name cask install is macOS only"
        return 1
    fi
    brew install --cask "$name" || { print_warn "Failed to install $name"; return 1; }
    print_success "$name installed"
}

# Prompt user for comma-separated selections from a numbered list
# Usage: prompt_selection "header" item1 item2 item3...
# Returns selected indices (0-based) in SELECTED_INDICES array
prompt_selection() {
    local header="$1"
    shift
    local items=("$@")
    local count=${#items[@]}

    echo ""
    echo -e "${BOLD}$header${NC}"
    echo ""
    for i in "${!items[@]}"; do
        echo "  $((i + 1))) ${items[$i]}"
    done
    echo ""
    echo "  a) All"
    echo "  q) Skip"
    echo ""
    read -rp "Select (comma-separated, e.g. 1,3,5): " selection

    SELECTED_INDICES=()

    if [[ "$selection" == "q" || "$selection" == "Q" ]]; then
        return 0
    fi

    if [[ "$selection" == "a" || "$selection" == "A" ]]; then
        for ((i = 0; i < count; i++)); do
            SELECTED_INDICES+=("$i")
        done
        return 0
    fi

    IFS=',' read -ra choices <<< "$selection"
    for choice in "${choices[@]}"; do
        choice=$(echo "$choice" | tr -d ' ')
        if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= count)); then
            SELECTED_INDICES+=("$((choice - 1))")
        fi
    done
}

# Confirm before proceeding
confirm() {
    local msg="${1:-Continue?}"
    read -rp "$msg [y/N]: " response
    [[ "$response" =~ ^[Yy]$ ]]
}
