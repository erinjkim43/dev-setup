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
    # Handle help early before system detection
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi

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
