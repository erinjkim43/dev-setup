#!/bin/bash

check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warn "Running as root user detected!"
        echo ""
        echo "For security reasons, it's recommended to run this script as a regular user."
        echo "Running dev tools as root can be dangerous and may cause permission issues."
        echo ""
        echo "To create a regular user and switch to it:"
        echo "  sudo adduser yourusername"
        echo "  sudo usermod -aG sudo yourusername"
        echo "  su - yourusername"
        echo ""

        if ! confirm "Continue as root anyway?"; then
            echo "Exiting. Please create a regular user and run this script again."
            exit 1
        fi

        print_warn "Continuing as root (not recommended)..."
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
        else
            print_error "Unsupported Linux distribution - only Ubuntu/Debian supported"
            exit 1
        fi
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi

    print_success "Detected OS: $OS"
    print_success "Package manager: $PACKAGE_MANAGER"
}

install_package_manager() {
    if [[ "$OS" == "macos" ]]; then
        if ! command -v brew >/dev/null 2>&1; then
            print_step "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
            print_installed "Homebrew"
        fi
    elif [[ "$PACKAGE_MANAGER" == "apt" ]]; then
        print_step "Updating apt package index..."
        sudo apt update -qq

        # Ensure essential build dependencies are present
        local deps=("curl" "build-essential" "fontconfig" "unzip")
        for dep in "${deps[@]}"; do
            pkg_install "$dep"
        done
    fi
}
