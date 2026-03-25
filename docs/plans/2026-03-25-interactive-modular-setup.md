# Interactive Modular Setup Overhaul

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform the dev-setup-automation repo into a fully interactive, modular installer where the user picks what to install from categorized menus, with idempotent "already installed" checks and a cleaner architecture.

**Architecture:** Single entrypoint (`setup.sh`) replaces both `bootstrap.sh` and `optional-tools.sh`. A shared UI library (`lib/ui.sh`) provides the interactive menu/checkbox system. Each installable component gets its own module file under `lib/modules/` for true modularity. The main script presents grouped categories and the user toggles what they want.

**Tech Stack:** Bash (no external dependencies for the installer itself), cross-platform macOS + Ubuntu/Debian.

---

## Design Decisions

### Single Entrypoint
- `setup.sh` replaces `bootstrap.sh` + `optional-tools.sh`
- Old scripts are deleted (not deprecated with wrappers)
- User runs `./setup.sh` and gets an interactive experience

### Module Structure
Each installable thing is a function in a category file under `lib/modules/`:
```
lib/modules/core.sh       # git, neovim, tmux, zsh, node, python
lib/modules/languages.sh  # rust, go, ruby
lib/modules/cli-tools.sh  # fzf, ripgrep, fd, bat, delta, lazygit, yazi, etc.
lib/modules/apps.sh       # docker, fonts
lib/modules/config.sh     # ssh, dotfiles (yadm), tpm, shell config, neovim plugins
```

### Interactive Menu Flow
```
=== Dev Environment Setup ===

Detected: macOS with Homebrew

Select categories to install (space to toggle, enter to confirm):

  [Core Packages]
  [x] git
  [x] neovim
  [x] tmux
  [x] zsh
  [x] node
  [x] python3

  [Languages]
  [ ] rust
  [ ] go
  [ ] ruby

  [CLI Tools]
  [ ] fzf
  [ ] ripgrep
  [ ] fd
  [ ] bat
  [ ] git-delta
  [ ] lazygit
  [ ] eza
  [ ] yazi
  [ ] tree
  [ ] htop
  [ ] jq
  [ ] wget

  [Apps]
  [ ] docker
  [ ] nerd-fonts (Meslo)

  [Configuration]
  [ ] ssh-keys
  [ ] dotfiles (yadm)
  [ ] tmux-plugin-manager
  [ ] zsh-as-default-shell
  [ ] neovim-plugins

  [a] Select all  [n] Select none  [Enter] Confirm
```

Since robust terminal checkbox UIs in pure bash are fragile, we'll use a simpler numbered-category approach that works reliably:

```
=== Dev Environment Setup ===

Detected: macOS with Homebrew

Categories:
  1) Core packages (git, neovim, tmux, zsh, node, python)
  2) Languages (rust, go, ruby)
  3) CLI tools (fzf, ripgrep, fd, bat, delta, lazygit, eza, yazi...)
  4) Apps (docker, nerd-fonts)
  5) Configuration (ssh, dotfiles, tpm, shell, neovim plugins)
  a) All of the above
  q) Quit

Select (comma-separated, e.g. 1,3,5):
```

Within each category, individual items can be toggled:
```
Core packages - select which to install:
  1) git          [installed]
  2) neovim
  3) tmux
  4) zsh          [installed]
  5) node
  6) python3      [installed]
  a) All    s) Skip already installed, install rest    q) Back

Select:
```

### Idempotent Checks
Every install function checks if the tool is already present and reports `[installed]` status. This replaces the inconsistent checking that exists today.

### Remove Duplication
- Rust install exists in both `packages.sh` and `optional-tools.sh` - consolidate into `languages.sh`
- `ripgrep` is in both core and optional - keep only in cli-tools

### Fix Stale Documentation
- CLAUDE.md references a `configs/` dir that doesn't exist
- README mentions WezTerm and Flatpak which aren't in scripts
- Update both to match reality

---

## Tasks

### Task 1: Create lib/ui.sh - shared UI helpers

**Files:**
- Create: `lib/ui.sh`

**Step 1: Write lib/ui.sh**

This provides all the menu/prompt/status functions used by the rest of the system.

```bash
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
# Usage: prompt_selection "header" items_array selected_array
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
```

**Step 2: Commit**

```bash
git add lib/ui.sh
git commit -m "feat: add shared UI helper library for interactive menus"
```

---

### Task 2: Create lib/modules/core.sh - core package modules

**Files:**
- Create: `lib/modules/core.sh`

**Step 1: Write lib/modules/core.sh**

Core packages that most dev setups need. Each is individually installable.

```bash
#!/bin/bash

# Core package definitions per platform
# Each function installs one tool with idempotent checking

install_git() {
    pkg_install "git"
}

install_neovim() {
    if is_installed "nvim"; then
        print_installed "neovim"
        return 0
    fi
    pkg_install "neovim" "nvim"
}

install_tmux() {
    pkg_install "tmux"
}

install_zsh() {
    pkg_install "zsh"
}

install_node() {
    if is_installed "node"; then
        print_installed "node"
        return 0
    fi
    case "$PACKAGE_MANAGER" in
        "brew") pkg_install "node" ;;
        "apt")
            pkg_install "nodejs" "node"
            pkg_install "npm"
            ;;
    esac
}

install_python() {
    if is_installed "python3"; then
        print_installed "python3"
        return 0
    fi
    case "$PACKAGE_MANAGER" in
        "brew") pkg_install "python3" ;;
        "apt")
            pkg_install "python3"
            pkg_install "python3-pip" "pip3"
            ;;
    esac
}

# Convenience: install all core packages
install_all_core() {
    print_header "Core Packages"
    install_git
    install_neovim
    install_tmux
    install_zsh
    install_node
    install_python
}

# Interactive core selection
select_core_packages() {
    local items=("git" "neovim" "tmux" "zsh" "node" "python3")
    local funcs=(install_git install_neovim install_tmux install_zsh install_node install_python)

    prompt_selection "Core Packages" "${items[@]}"

    if [[ ${#SELECTED_INDICES[@]} -eq 0 ]]; then
        print_skipped "core packages"
        return 0
    fi

    print_header "Installing Core Packages"
    for idx in "${SELECTED_INDICES[@]}"; do
        ${funcs[$idx]}
    done
}
```

**Step 2: Commit**

```bash
git add lib/modules/core.sh
git commit -m "feat: add core packages module with individual install functions"
```

---

### Task 3: Create lib/modules/languages.sh - programming language modules

**Files:**
- Create: `lib/modules/languages.sh`

**Step 1: Write lib/modules/languages.sh**

Consolidates Rust (previously duplicated), Go, and Ruby.

```bash
#!/bin/bash

install_rust() {
    if is_installed "rustc"; then
        print_installed "rust"
        return 0
    fi
    print_step "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env" 2>/dev/null || true
    print_success "rust installed"
}

install_go() {
    if is_installed "go"; then
        print_installed "go"
        return 0
    fi
    case "$PACKAGE_MANAGER" in
        "brew") pkg_install "go" ;;
        "apt") pkg_install "golang-go" "go" ;;
    esac
}

install_ruby() {
    if is_installed "ruby"; then
        print_installed "ruby"
        return 0
    fi
    case "$PACKAGE_MANAGER" in
        "brew")
            pkg_install "ruby"
            pkg_install "rbenv"
            ;;
        "apt")
            pkg_install "ruby-full" "ruby"
            pkg_install "rbenv"
            ;;
    esac
}

install_all_languages() {
    print_header "Programming Languages"
    install_rust
    install_go
    install_ruby
}

select_languages() {
    local items=("rust" "go" "ruby")
    local funcs=(install_rust install_go install_ruby)

    prompt_selection "Programming Languages" "${items[@]}"

    if [[ ${#SELECTED_INDICES[@]} -eq 0 ]]; then
        print_skipped "languages"
        return 0
    fi

    print_header "Installing Languages"
    for idx in "${SELECTED_INDICES[@]}"; do
        ${funcs[$idx]}
    done
}
```

**Step 2: Commit**

```bash
git add lib/modules/languages.sh
git commit -m "feat: add languages module, consolidate duplicate rust install"
```

---

### Task 4: Create lib/modules/cli-tools.sh - CLI tool modules

**Files:**
- Create: `lib/modules/cli-tools.sh`

**Step 1: Write lib/modules/cli-tools.sh**

Each CLI tool is individually installable. Handles the platform-specific installs for tools that aren't in apt (delta, lazygit, yazi).

```bash
#!/bin/bash

install_fzf() { pkg_install "fzf"; }
install_fd() {
    if is_installed "fd"; then
        print_installed "fd"
        return 0
    fi
    case "$PACKAGE_MANAGER" in
        "brew") pkg_install "fd" ;;
        "apt") pkg_install "fd-find" "fdfind" ;;
    esac
}
install_bat() {
    if is_installed "bat"; then
        print_installed "bat"
        return 0
    fi
    case "$PACKAGE_MANAGER" in
        "brew") pkg_install "bat" ;;
        "apt") pkg_install "bat" "batcat" ;;
    esac
}
install_ripgrep() { pkg_install "ripgrep" "rg"; }
install_eza() {
    if is_installed "eza"; then
        print_installed "eza"
        return 0
    fi
    case "$PACKAGE_MANAGER" in
        "brew") pkg_install "eza" ;;
        "apt")
            print_step "Installing eza via apt repository..."
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
            sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
            sudo apt update -qq
            sudo apt install -y eza || print_warn "Failed to install eza"
            ;;
    esac
}
install_delta() {
    if is_installed "delta"; then
        print_installed "git-delta"
        return 0
    fi
    case "$PACKAGE_MANAGER" in
        "brew") pkg_install "git-delta" "delta" ;;
        "apt")
            print_step "Installing git-delta..."
            local version
            version=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
            curl -fsSL "https://github.com/dandavison/delta/releases/download/${version}/git-delta_${version}_amd64.deb" -o "/tmp/git-delta.deb"
            sudo dpkg -i "/tmp/git-delta.deb" || print_warn "Failed to install git-delta"
            rm -f "/tmp/git-delta.deb"
            ;;
    esac
}
install_lazygit() {
    if is_installed "lazygit"; then
        print_installed "lazygit"
        return 0
    fi
    case "$PACKAGE_MANAGER" in
        "brew") pkg_install "lazygit" ;;
        "apt")
            print_step "Installing lazygit..."
            local version
            version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
            curl -fsSL "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_Linux_x86_64.tar.gz" -o "/tmp/lazygit.tar.gz"
            tar -xzf "/tmp/lazygit.tar.gz" -C "/tmp"
            sudo install "/tmp/lazygit" "/usr/local/bin/lazygit"
            rm -f "/tmp/lazygit.tar.gz" "/tmp/lazygit"
            ;;
    esac
}
install_yazi() {
    if is_installed "yazi"; then
        print_installed "yazi"
        return 0
    fi
    case "$PACKAGE_MANAGER" in
        "brew") pkg_install "yazi" ;;
        "apt")
            print_step "Installing yazi..."
            local tarball="yazi-x86_64-unknown-linux-gnu"
            curl -fsSL "https://github.com/sxyazi/yazi/releases/latest/download/${tarball}.tar.gz" -o "/tmp/yazi.tar.gz"
            tar -xzf "/tmp/yazi.tar.gz" -C "/tmp"
            sudo install "/tmp/${tarball}/yazi" "/usr/local/bin/yazi"
            rm -rf "/tmp/yazi.tar.gz" "/tmp/${tarball}"
            ;;
    esac
}
install_tree() { pkg_install "tree"; }
install_htop() { pkg_install "htop"; }
install_jq() { pkg_install "jq"; }
install_wget() { pkg_install "wget"; }

install_all_cli_tools() {
    print_header "CLI Tools"
    install_fzf
    install_ripgrep
    install_fd
    install_bat
    install_eza
    install_delta
    install_lazygit
    install_yazi
    install_tree
    install_htop
    install_jq
    install_wget
}

select_cli_tools() {
    local items=("fzf" "ripgrep" "fd" "bat" "eza" "git-delta" "lazygit" "yazi" "tree" "htop" "jq" "wget")
    local funcs=(install_fzf install_ripgrep install_fd install_bat install_eza install_delta install_lazygit install_yazi install_tree install_htop install_jq install_wget)

    prompt_selection "CLI Tools" "${items[@]}"

    if [[ ${#SELECTED_INDICES[@]} -eq 0 ]]; then
        print_skipped "CLI tools"
        return 0
    fi

    print_header "Installing CLI Tools"
    for idx in "${SELECTED_INDICES[@]}"; do
        ${funcs[$idx]}
    done
}
```

**Step 2: Commit**

```bash
git add lib/modules/cli-tools.sh
git commit -m "feat: add CLI tools module with individual install functions"
```

---

### Task 5: Create lib/modules/apps.sh - application modules

**Files:**
- Create: `lib/modules/apps.sh`

**Step 1: Write lib/modules/apps.sh**

Docker and Nerd Fonts.

```bash
#!/bin/bash

install_docker() {
    if is_installed "docker"; then
        print_installed "docker"
        return 0
    fi
    print_step "Installing Docker..."
    case "$PACKAGE_MANAGER" in
        "brew")
            brew install --cask docker || print_warn "Failed to install Docker"
            ;;
        "apt")
            curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
            sh /tmp/get-docker.sh
            sudo usermod -aG docker "$USER"
            sudo systemctl enable docker
            sudo systemctl start docker
            rm -f /tmp/get-docker.sh
            ;;
    esac
    print_success "docker installed"
}

install_nerd_fonts() {
    print_step "Installing Meslo Nerd Font..."
    if [[ "$OS" == "macos" ]]; then
        if brew list --cask font-meslo-lg-nerd-font >/dev/null 2>&1; then
            print_installed "Meslo Nerd Font"
            return 0
        fi
        brew install --cask font-meslo-lg-nerd-font || print_warn "Failed to install Meslo Nerd Font"
    else
        local fonts_dir="$HOME/.local/share/fonts"
        if [[ -f "$fonts_dir/MesloLGS NF Regular.ttf" ]]; then
            print_installed "Meslo Nerd Font"
            return 0
        fi
        mkdir -p "$fonts_dir"
        local base_url="https://github.com/romkatv/powerlevel10k-media/raw/master"
        curl -fsSLo "$fonts_dir/MesloLGS NF Regular.ttf" "$base_url/MesloLGS%20NF%20Regular.ttf"
        curl -fsSLo "$fonts_dir/MesloLGS NF Bold.ttf" "$base_url/MesloLGS%20NF%20Bold.ttf"
        curl -fsSLo "$fonts_dir/MesloLGS NF Italic.ttf" "$base_url/MesloLGS%20NF%20Italic.ttf"
        curl -fsSLo "$fonts_dir/MesloLGS NF Bold Italic.ttf" "$base_url/MesloLGS%20NF%20Bold%20Italic.ttf"
        fc-cache -fv >/dev/null 2>&1
    fi
    print_success "Meslo Nerd Font installed"
}

install_all_apps() {
    print_header "Apps"
    install_docker
    install_nerd_fonts
}

select_apps() {
    local items=("docker" "nerd-fonts (Meslo)")
    local funcs=(install_docker install_nerd_fonts)

    prompt_selection "Apps" "${items[@]}"

    if [[ ${#SELECTED_INDICES[@]} -eq 0 ]]; then
        print_skipped "apps"
        return 0
    fi

    print_header "Installing Apps"
    for idx in "${SELECTED_INDICES[@]}"; do
        ${funcs[$idx]}
    done
}
```

**Step 2: Commit**

```bash
git add lib/modules/apps.sh
git commit -m "feat: add apps module (docker, nerd fonts)"
```

---

### Task 6: Create lib/modules/config.sh - configuration modules

**Files:**
- Create: `lib/modules/config.sh`

**Step 1: Write lib/modules/config.sh**

SSH, dotfiles, TPM, shell config, neovim plugins. Adapted from existing `lib/dotfiles.sh` and `lib/utils.sh`.

```bash
#!/bin/bash

DOTS_REPO="https://github.com/erinjkim43/dots.git"
DOTS_SSH="git@github.com:erinjkim43/dots.git"

setup_ssh() {
    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        print_installed "SSH key"
        ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null || true
        return 0
    fi

    print_step "Generating SSH key..."
    read -rp "Enter your email for SSH key: " email
    ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""

    eval "$(ssh-agent -s)" >/dev/null
    ssh-add "$HOME/.ssh/id_ed25519"

    echo ""
    echo -e "${BOLD}Your SSH public key:${NC}"
    echo "---"
    cat "$HOME/.ssh/id_ed25519.pub"
    echo "---"
    echo ""
    echo "Add it at: https://github.com/settings/ssh/new"
    echo ""
    read -rp "Press Enter after adding the key to GitHub..."

    ssh -T git@github.com 2>&1 || true
    print_success "SSH key configured"
}

setup_dotfiles() {
    print_step "Setting up dotfiles with yadm..."

    if ! is_installed "yadm"; then
        pkg_install "yadm"
    fi

    if [[ -d "$HOME/.config/yadm" ]]; then
        print_installed "dotfiles"
        yadm pull 2>/dev/null || true
        return 0
    fi

    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        yadm clone "$DOTS_SSH"
    else
        yadm clone "$DOTS_REPO"
    fi
    print_success "dotfiles installed"
}

setup_tpm() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ -d "$tpm_dir" ]]; then
        print_installed "TPM (Tmux Plugin Manager)"
        return 0
    fi
    print_step "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
    print_success "TPM installed"
}

configure_default_shell() {
    if [[ "$SHELL" == *"zsh"* ]]; then
        print_installed "zsh as default shell"
        return 0
    fi
    local zsh_path
    zsh_path=$(which zsh 2>/dev/null)
    if [[ -z "$zsh_path" ]]; then
        print_warn "zsh not found, skipping shell change"
        return 1
    fi
    print_step "Setting zsh as default shell..."
    chsh -s "$zsh_path"
    print_success "zsh set as default shell"
}

setup_neovim_plugins() {
    if ! is_installed "nvim"; then
        print_warn "Neovim not found, skipping plugin setup"
        return 0
    fi

    print_step "Pre-installing Neovim plugins..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || print_warn "Lazy plugin sync had issues (normal on first run)"

    print_step "Installing LSP servers via Mason..."
    local servers=(
        "lua_ls"
        "typescript-language-server"
        "tailwindcss-language-server"
        "rust-analyzer"
        "pyright"
        "bash-language-server"
        "json-lsp"
        "yaml-language-server"
        "marksman"
        "prettier"
        "stylua"
        "isort"
        "black"
        "eslint_d"
        "shfmt"
    )

    for server in "${servers[@]}"; do
        nvim --headless -c "MasonInstall $server" -c qall 2>/dev/null || print_warn "Failed to install $server"
    done
    print_success "Neovim plugins installed"
}

install_all_config() {
    print_header "Configuration"
    setup_ssh
    setup_dotfiles
    setup_tpm
    configure_default_shell
    setup_neovim_plugins
}

select_config() {
    local items=("ssh-keys" "dotfiles (yadm)" "tmux-plugin-manager" "zsh-as-default-shell" "neovim-plugins")
    local funcs=(setup_ssh setup_dotfiles setup_tpm configure_default_shell setup_neovim_plugins)

    prompt_selection "Configuration" "${items[@]}"

    if [[ ${#SELECTED_INDICES[@]} -eq 0 ]]; then
        print_skipped "configuration"
        return 0
    fi

    print_header "Setting Up Configuration"
    for idx in "${SELECTED_INDICES[@]}"; do
        ${funcs[$idx]}
    done
}
```

**Step 2: Commit**

```bash
git add lib/modules/config.sh
git commit -m "feat: add config module (ssh, dotfiles, tpm, shell, neovim)"
```

---

### Task 7: Write the new setup.sh entrypoint

**Files:**
- Create: `setup.sh`

**Step 1: Write setup.sh**

Single interactive entrypoint that replaces both `bootstrap.sh` and `optional-tools.sh`.

```bash
#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries
source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/system.sh"
source "$SCRIPT_DIR/lib/modules/core.sh"
source "$SCRIPT_DIR/lib/modules/languages.sh"
source "$SCRIPT_DIR/lib/modules/cli-tools.sh"
source "$SCRIPT_DIR/lib/modules/apps.sh"
source "$SCRIPT_DIR/lib/modules/config.sh"

usage() {
    echo "Usage: ./setup.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --all         Install everything non-interactively"
    echo "  --core        Install core packages only"
    echo "  --langs       Install programming languages only"
    echo "  --cli         Install CLI tools only"
    echo "  --apps        Install apps only"
    echo "  --config      Run configuration setup only"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "With no options, runs in interactive mode."
}

main() {
    check_root
    detect_os
    install_package_manager

    # Handle CLI flags for non-interactive use
    if [[ $# -gt 0 ]]; then
        case "$1" in
            --all)
                install_all_core
                install_all_languages
                install_all_cli_tools
                install_all_apps
                install_all_config
                ;;
            --core)   install_all_core ;;
            --langs)  install_all_languages ;;
            --cli)    install_all_cli_tools ;;
            --apps)   install_all_apps ;;
            --config) install_all_config ;;
            -h|--help) usage; exit 0 ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
        echo ""
        print_success "Done!"
        exit 0
    fi

    # Interactive mode
    print_header "Dev Environment Setup"
    echo -e "Detected: ${BOLD}$OS${NC} with ${BOLD}$PACKAGE_MANAGER${NC}"

    while true; do
        echo ""
        echo -e "${BOLD}Categories:${NC}"
        echo "  1) Core packages (git, neovim, tmux, zsh, node, python)"
        echo "  2) Languages (rust, go, ruby)"
        echo "  3) CLI tools (fzf, ripgrep, fd, bat, delta, lazygit, eza, yazi...)"
        echo "  4) Apps (docker, nerd-fonts)"
        echo "  5) Configuration (ssh, dotfiles, tpm, shell, neovim plugins)"
        echo "  a) All of the above"
        echo "  q) Quit"
        echo ""
        read -rp "Select categories (comma-separated, e.g. 1,3,5): " selection

        case "$selection" in
            q|Q)
                echo ""
                print_success "Done! Restart your terminal to apply changes."
                exit 0
                ;;
            a|A)
                select_core_packages
                select_languages
                select_cli_tools
                select_apps
                select_config
                ;;
            *)
                IFS=',' read -ra cats <<< "$selection"
                for cat in "${cats[@]}"; do
                    cat=$(echo "$cat" | tr -d ' ')
                    case "$cat" in
                        1) select_core_packages ;;
                        2) select_languages ;;
                        3) select_cli_tools ;;
                        4) select_apps ;;
                        5) select_config ;;
                        *) print_warn "Unknown category: $cat" ;;
                    esac
                done
                ;;
        esac

        echo ""
        if ! confirm "Install more?"; then
            echo ""
            print_success "Done! Restart your terminal to apply changes."
            exit 0
        fi
    done
}

main "$@"
```

**Step 2: Make it executable**

```bash
chmod +x setup.sh
```

**Step 3: Commit**

```bash
git add setup.sh
git commit -m "feat: add interactive setup.sh entrypoint replacing bootstrap.sh + optional-tools.sh"
```

---

### Task 8: Delete old files, clean up lib/

**Files:**
- Delete: `bootstrap.sh`
- Delete: `optional-tools.sh`
- Delete: `lib/packages.sh`
- Delete: `lib/dotfiles.sh`
- Delete: `lib/utils.sh`

**Step 1: Remove old files**

All functionality has been migrated to the new module structure. `lib/system.sh` is kept as-is since it's still used.

```bash
rm bootstrap.sh optional-tools.sh lib/packages.sh lib/dotfiles.sh lib/utils.sh
```

**Step 2: Commit**

```bash
git add -A
git commit -m "chore: remove old bootstrap.sh, optional-tools.sh, and migrated lib files"
```

---

### Task 9: Update README.md

**Files:**
- Modify: `README.md`

**Step 1: Rewrite README to match new structure**

Update to reflect single entrypoint, interactive mode, CLI flags, new file structure. Remove references to WezTerm and Flatpak (not in scripts). Remove yadm-specific update instructions (now handled by the installer).

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update README for new interactive setup"
```

---

### Task 10: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Rewrite CLAUDE.md to match new architecture**

Remove references to `configs/` directory (doesn't exist). Update function names, file paths, and architecture description to match new module structure. Remove references to `bootstrap.sh` and `optional-tools.sh`.

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md for new modular architecture"
```

---

### Task 11: Manual testing pass

**No files changed - verification only.**

**Step 1: Verify setup.sh runs without syntax errors**

```bash
bash -n setup.sh
```

**Step 2: Verify all lib files parse cleanly**

```bash
bash -n lib/ui.sh
bash -n lib/system.sh
bash -n lib/modules/core.sh
bash -n lib/modules/languages.sh
bash -n lib/modules/cli-tools.sh
bash -n lib/modules/apps.sh
bash -n lib/modules/config.sh
```

**Step 3: Test --help flag**

```bash
./setup.sh --help
```

**Step 4: Spot-test interactive mode starts correctly**

Run `./setup.sh`, verify the menu displays, select `q` to quit.
