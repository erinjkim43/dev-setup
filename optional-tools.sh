#!/bin/bash

set -e

echo "🔧 Installing optional development tools..."

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PACKAGE_MANAGER="brew"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if command -v apt >/dev/null 2>&1; then
            PACKAGE_MANAGER="apt"
        elif command -v dnf >/dev/null 2>&1; then
            PACKAGE_MANAGER="dnf"
        elif command -v pacman >/dev/null 2>&1; then
            PACKAGE_MANAGER="pacman"
        fi
    fi
}

install_docker() {
    echo "🐳 Installing Docker..."
    case "$PACKAGE_MANAGER" in
        "brew")
            brew install --cask docker
            ;;
        "apt")
            curl -fsSL https://get.docker.com -o get-docker.sh
            sh get-docker.sh
            sudo usermod -aG docker "$USER"
            rm get-docker.sh
            ;;
        "dnf")
            sudo dnf install -y docker
            sudo systemctl enable docker
            sudo usermod -aG docker "$USER"
            ;;
        "pacman")
            sudo pacman -S --noconfirm docker
            sudo systemctl enable docker
            sudo usermod -aG docker "$USER"
            ;;
    esac
}

install_rust() {
    echo "🦀 Installing Rust..."
    if ! command -v rustc >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    else
        echo "✅ Rust already installed"
    fi
}

install_go() {
    echo "🐹 Installing Go..."
    case "$PACKAGE_MANAGER" in
        "brew")
            brew install go
            ;;
        "apt")
            sudo apt install -y golang-go
            ;;
        "dnf")
            sudo dnf install -y golang
            ;;
        "pacman")
            sudo pacman -S --noconfirm go
            ;;
    esac
}

install_ruby() {
    echo "💎 Installing Ruby..."
    case "$PACKAGE_MANAGER" in
        "brew")
            brew install ruby rbenv
            ;;
        "apt")
            sudo apt install -y ruby-full rbenv
            ;;
        "dnf")
            sudo dnf install -y ruby rbenv
            ;;
        "pacman")
            sudo pacman -S --noconfirm ruby
            ;;
    esac
}

install_dev_tools() {
    echo "🛠️ Installing additional dev tools..."
    case "$PACKAGE_MANAGER" in
        "brew")
            tools=(
                "fzf"
                "ripgrep"
                "fd"
                "bat"
                "exa"
                "git-delta"
                "lazygit"
                "tree"
                "htop"
                "jq"
                "wget"
            )
            for tool in "${tools[@]}"; do
                brew install "$tool" || echo "⚠️ Failed to install $tool"
            done
            ;;
        "apt")
            tools=(
                "fzf"
                "ripgrep"
                "fd-find"
                "bat"
                "tree"
                "htop"
                "jq"
                "wget"
                "curl"
                "unzip"
            )
            for tool in "${tools[@]}"; do
                sudo apt install -y "$tool" || echo "⚠️ Failed to install $tool"
            done
            ;;
        "dnf")
            tools=(
                "fzf"
                "ripgrep"
                "fd-find"
                "bat"
                "tree"
                "htop"
                "jq"
                "wget"
                "curl"
                "unzip"
            )
            for tool in "${tools[@]}"; do
                sudo dnf install -y "$tool" || echo "⚠️ Failed to install $tool"
            done
            ;;
        "pacman")
            tools=(
                "fzf"
                "ripgrep"
                "fd"
                "bat"
                "exa"
                "tree"
                "htop"
                "jq"
                "wget"
                "curl"
                "unzip"
            )
            for tool in "${tools[@]}"; do
                sudo pacman -S --noconfirm "$tool" || echo "⚠️ Failed to install $tool"
            done
            ;;
    esac
}

show_menu() {
    echo ""
    echo "Select optional tools to install:"
    echo "1) Docker"
    echo "2) Rust"
    echo "3) Go"
    echo "4) Ruby"
    echo "5) Additional dev tools (fzf, ripgrep, etc.)"
    echo "6) All of the above"
    echo "q) Quit"
    echo ""
    read -p "Enter your choice: " choice
}

main() {
    detect_os
    
    while true; do
        show_menu
        case $choice in
            1) install_docker ;;
            2) install_rust ;;
            3) install_go ;;
            4) install_ruby ;;
            5) install_dev_tools ;;
            6) 
                install_docker
                install_rust
                install_go
                install_ruby
                install_dev_tools
                ;;
            q|Q) 
                echo "👋 Goodbye!"
                exit 0
                ;;
            *) 
                echo "❌ Invalid option"
                ;;
        esac
        echo ""
        echo "✅ Installation complete!"
        echo ""
    done
}

main "$@"