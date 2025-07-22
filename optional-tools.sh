#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source system detection
source "$SCRIPT_DIR/lib/system.sh"

echo "🔧 Installing optional development tools..."

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
            sudo systemctl enable docker
            sudo systemctl start docker
            rm get-docker.sh
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
                "git-delta"
                "lazygit"
                "tree"
                "htop"
                "jq"
                "wget"
                "yazi"
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
            
            
            # Install git-delta separately
            echo "Installing git-delta..."
            DELTA_VERSION=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
            curl -L "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb" -o "/tmp/git-delta.deb"
            sudo dpkg -i "/tmp/git-delta.deb" || echo "⚠️ Failed to install git-delta"
            rm "/tmp/git-delta.deb"
            
            # Install lazygit separately
            echo "Installing lazygit..."
            LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
            curl -L "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" -o "/tmp/lazygit.tar.gz"
            tar -xzf "/tmp/lazygit.tar.gz" -C "/tmp"
            sudo cp "/tmp/lazygit" "/usr/local/bin/"
            rm "/tmp/lazygit*" || echo "⚠️ Failed to install lazygit"
            
            # Install yazi separately
            echo "Installing yazi..."
            curl -L "https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.tar.gz" -o "/tmp/yazi.tar.gz"
            tar -xzf "/tmp/yazi.tar.gz" -C "/tmp"
            sudo cp "/tmp/yazi-x86_64-unknown-linux-gnu/yazi" "/usr/local/bin/"
            rm -rf "/tmp/yazi*" || echo "⚠️ Failed to install yazi"
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
    echo "5) Additional dev tools (fzf, ripgrep, lazygit, etc.)"
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