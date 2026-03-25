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
