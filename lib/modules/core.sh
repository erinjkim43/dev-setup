#!/bin/bash

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

install_all_core() {
    print_header "Core Packages"
    install_git
    install_neovim
    install_tmux
    install_zsh
    install_node
    install_python
}

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
