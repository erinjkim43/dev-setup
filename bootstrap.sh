#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all library modules
source "$SCRIPT_DIR/lib/system.sh"
source "$SCRIPT_DIR/lib/packages.sh"
source "$SCRIPT_DIR/lib/dotfiles.sh"
source "$SCRIPT_DIR/lib/utils.sh"

echo "🚀 Starting cross-platform dev environment setup..."

main() {
    check_root
    detect_os
    install_package_manager
    install_core_packages
    setup_ssh
    install_nerd_fonts
    setup_tpm
    install_dotfiles
    configure_shell
    
    echo ""
    echo "🎉 Dev environment setup complete!"
    echo "📝 Please restart your terminal or run 'source ~/.zshrc'"
    echo "🔑 SSH key configured for GitHub push access"
    echo "🔤 Nerd Font installed - configure your terminal to use it"
    echo "🔧 TPM installed - tmux plugins will be available"
    echo "🔧 Your dotfiles are managed by yadm - use 'yadm status' to check"
    echo "⚡ To install optional tools, run: ./optional-tools.sh"
}

main "$@"