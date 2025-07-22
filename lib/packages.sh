#!/bin/bash

install_core_packages() {
    echo "📦 Installing core packages..."
    
    case "$PACKAGE_MANAGER" in
        "brew")
            packages=(
                "git"
                "yadm"
                "neovim"
                "tmux"
                "zsh"
                "node"
                "python3"
                "eza"
                "ripgrep"
            )
            for package in "${packages[@]}"; do
                echo "Installing $package..."
                brew install "$package" || echo "⚠️ Failed to install $package"
            done
            
            echo "Installing Rust via rustup..."
            if ! command -v rustc >/dev/null 2>&1; then
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                source "$HOME/.cargo/env"
            else
                echo "✅ Rust already installed"
            fi
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
                "fontconfig"
                "fzf"
                "ripgrep"
            )
            for package in "${packages[@]}"; do
                echo "Installing $package..."
                sudo apt install -y "$package" || echo "⚠️ Failed to install $package"
            done
            
            # Install eza separately via repository
            echo "Installing eza..."
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
            sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
            sudo apt update
            sudo apt install -y eza || echo "⚠️ Failed to install eza"
            
            echo "Installing Rust via rustup..."
            if ! command -v rustc >/dev/null 2>&1; then
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                source "$HOME/.cargo/env"
            else
                echo "✅ Rust already installed"
            fi
            ;;
    esac
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