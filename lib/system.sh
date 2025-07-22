#!/bin/bash

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
            DISTRO="ubuntu"
        else
            echo "❌ Unsupported Linux distribution - only Ubuntu/Debian supported"
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