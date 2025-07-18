#!/bin/bash

set -e

REPO_URL="https://github.com/erinjkim43/dots.git"
DOTFILES_DIR="$HOME/.config/yadm"

echo "🚀 Starting cross-platform dev environment setup..."

check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo "⚠️ Running as root user detected!"
        echo ""
        echo "🔒 For security reasons, it's recommended to run this script as a regular user."
        echo "Running dev tools as root can be dangerous and may cause permission issues."
        echo ""
        echo "To create a regular user and switch to it:"
        echo "  sudo adduser yourusername"
        echo "  sudo usermod -aG sudo yourusername"
        echo "  su - yourusername"
        echo ""
        read -p "Continue as root anyway? (y/N): " continue_as_root
        
        if [[ ! "$continue_as_root" =~ ^[Yy]$ ]]; then
            echo "👋 Exiting. Please create a regular user and run this script again."
            exit 1
        fi
        
        echo "⚠️ Continuing as root (not recommended)..."
        echo ""
    fi
}

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PACKAGE_MANAGER="brew"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if command -v apt >/dev/null 2>&1; then
            PACKAGE_MANAGER="apt"
            DISTRO="debian"
        elif command -v dnf >/dev/null 2>&1; then
            PACKAGE_MANAGER="dnf"
            DISTRO="fedora"
        elif command -v pacman >/dev/null 2>&1; then
            PACKAGE_MANAGER="pacman"
            DISTRO="arch"
        else
            echo "❌ Unsupported Linux distribution"
            exit 1
        fi
    else
        echo "❌ Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    echo "✅ Detected OS: $OS"
    echo "✅ Package manager: $PACKAGE_MANAGER"
}

install_package_manager() {
    if [[ "$OS" == "macos" ]]; then
        if ! command -v brew >/dev/null 2>&1; then
            echo "📦 Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
            echo "✅ Homebrew already installed"
        fi
    fi
}

install_packages() {
    echo "📦 Installing core packages..."
    
    case "$PACKAGE_MANAGER" in
        "brew")
            packages=(
                "git"
                "yadm"
                "neovim"
                "tmux"
                "zsh"
                "wezterm"
                "node"
                "python@3.11"
                "rustup"
            )
            for package in "${packages[@]}"; do
                echo "Installing $package..."
                brew install "$package" || echo "⚠️ Failed to install $package"
            done
            ;;
        "apt")
            sudo apt update
            packages=(
                "git"
                "yadm"
                "neovim"
                "tmux"
                "zsh"
                "curl"
                "build-essential"
                "python3"
                "python3-pip"
                "nodejs"
                "npm"
            )
            for package in "${packages[@]}"; do
                echo "Installing $package..."
                sudo apt install -y "$package" || echo "⚠️ Failed to install $package"
            done
            ;;
        "dnf")
            packages=(
                "git"
                "yadm"
                "neovim"
                "tmux"
                "zsh"
                "curl"
                "gcc"
                "python3"
                "python3-pip"
                "nodejs"
                "npm"
            )
            for package in "${packages[@]}"; do
                echo "Installing $package..."
                sudo dnf install -y "$package" || echo "⚠️ Failed to install $package"
            done
            ;;
        "pacman")
            packages=(
                "git"
                "yadm"
                "neovim"
                "tmux"
                "zsh"
                "curl"
                "base-devel"
                "python"
                "python-pip"
                "nodejs"
                "npm"
            )
            for package in "${packages[@]}"; do
                echo "Installing $package..."
                sudo pacman -S --noconfirm "$package" || echo "⚠️ Failed to install $package"
            done
            ;;
    esac
}

setup_ssh() {
    echo "🔑 Setting up SSH authentication..."
    
    if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        echo "Generating SSH key..."
        read -p "Enter your email for SSH key: " email
        ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""
        
        echo "Starting SSH agent..."
        eval "$(ssh-agent -s)"
        ssh-add "$HOME/.ssh/id_ed25519"
        
        echo ""
        echo "📋 Your SSH public key (copy this to GitHub):"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        cat "$HOME/.ssh/id_ed25519.pub"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "📖 Go to: https://github.com/settings/ssh/new"
        echo "1. Paste the key above"
        echo "2. Give it a title (e.g., 'Dev Machine $(date +%Y-%m-%d)')"
        echo "3. Click 'Add SSH key'"
        echo ""
        read -p "Press Enter after adding the SSH key to GitHub..."
        
        echo "Testing SSH connection..."
        ssh -T git@github.com || echo "⚠️ SSH test failed, but this might be normal"
    else
        echo "✅ SSH key already exists"
        ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null || true
    fi
}

install_nerd_fonts() {
    echo "🔤 Installing Nerd Fonts..."
    
    if [[ "$OS" == "macos" ]]; then
        if ! brew list --cask font-meslo-lg-nerd-font >/dev/null 2>&1; then
            echo "Installing Meslo Nerd Font via Homebrew..."
            brew tap homebrew/cask-fonts
            brew install --cask font-meslo-lg-nerd-font
        else
            echo "✅ Meslo Nerd Font already installed"
        fi
    else
        # Linux - download and install manually
        FONTS_DIR="$HOME/.local/share/fonts"
        mkdir -p "$FONTS_DIR"
        
        if [[ ! -f "$FONTS_DIR/MesloLGS NF Regular.ttf" ]]; then
            echo "Downloading Meslo Nerd Fonts..."
            cd "$FONTS_DIR"
            curl -fLo "MesloLGS NF Regular.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
            curl -fLo "MesloLGS NF Bold.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
            curl -fLo "MesloLGS NF Italic.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
            curl -fLo "MesloLGS NF Bold Italic.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
            fc-cache -fv
            echo "✅ Meslo Nerd Fonts installed"
        else
            echo "✅ Meslo Nerd Fonts already installed"
        fi
    fi
}

setup_tpm() {
    echo "🔧 Setting up TPM (Tmux Plugin Manager)..."
    
    TPM_DIR="$HOME/.tmux/plugins/tpm"
    if [[ ! -d "$TPM_DIR" ]]; then
        echo "Installing TPM..."
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
        echo "✅ TPM installed - plugins will be installed when tmux starts"
    else
        echo "✅ TPM already installed"
    fi
}

setup_dotfiles() {
    echo "🔧 Setting up dotfiles with yadm..."
    
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        echo "Cloning dotfiles repository..."
        
        # Try SSH first, fall back to HTTPS
        SSH_REPO_URL="git@github.com:erinjkim43/dots.git"
        if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
            echo "Using SSH to clone repository..."
            yadm clone "$SSH_REPO_URL"
        else
            echo "SSH not configured, using HTTPS..."
            yadm clone "$REPO_URL"
        fi
    else
        echo "✅ Dotfiles already cloned"
        yadm pull
    fi
    
    echo "Applying dotfile configurations..."
    yadm status
}

configure_shell() {
    echo "🐚 Configuring shell..."
    
    if [[ "$SHELL" != *"zsh"* ]]; then
        echo "Setting zsh as default shell..."
        if [[ "$OS" == "macos" ]]; then
            chsh -s /bin/zsh
        else
            chsh -s "$(which zsh)"
        fi
    else
        echo "✅ zsh already set as default shell"
    fi
}

main() {
    check_root
    detect_os
    install_package_manager
    install_packages
    setup_ssh
    install_nerd_fonts
    setup_tpm
    setup_dotfiles
    configure_shell
    
    echo ""
    echo "🎉 Dev environment setup complete!"
    echo "📝 Please restart your terminal or run 'source ~/.zshrc'"
    echo "🔧 Your dotfiles are managed by yadm - use 'yadm status' to check"
    echo "🔑 SSH key configured for GitHub push access"
    echo "🔤 Nerd Font installed - configure your terminal to use it"
    echo "🔧 TPM installed - tmux plugins will be available"
    echo "🎨 Shell configuration managed by your dotfiles"
}

main "$@"