#!/bin/bash

install_docker() {
    if is_installed "docker"; then
        print_installed "docker"
        return 0
    fi
    print_step "Installing Docker..."
    case "$PACKAGE_MANAGER" in
        "brew")
            brew install --cask docker || { print_warn "Failed to install Docker"; return 1; }
            ;;
        "apt")
            curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
            sh /tmp/get-docker.sh
            sudo usermod -aG docker "$USER"
            sudo systemctl enable docker
            sudo systemctl start docker
            rm -f /tmp/get-docker.sh
            ;;
    esac
    print_success "docker installed"
}

install_nerd_fonts() {
    print_step "Installing Meslo Nerd Font..."
    if [[ "$OS" == "macos" ]]; then
        if brew list --cask font-meslo-lg-nerd-font >/dev/null 2>&1; then
            print_installed "Meslo Nerd Font"
            return 0
        fi
        brew install --cask font-meslo-lg-nerd-font || { print_warn "Failed to install Meslo Nerd Font"; return 1; }
    else
        local fonts_dir="$HOME/.local/share/fonts"
        if [[ -f "$fonts_dir/MesloLGS NF Regular.ttf" ]]; then
            print_installed "Meslo Nerd Font"
            return 0
        fi
        mkdir -p "$fonts_dir"
        local base_url="https://github.com/romkatv/powerlevel10k-media/raw/master"
        curl -fsSLo "$fonts_dir/MesloLGS NF Regular.ttf" "$base_url/MesloLGS%20NF%20Regular.ttf"
        curl -fsSLo "$fonts_dir/MesloLGS NF Bold.ttf" "$base_url/MesloLGS%20NF%20Bold.ttf"
        curl -fsSLo "$fonts_dir/MesloLGS NF Italic.ttf" "$base_url/MesloLGS%20NF%20Italic.ttf"
        curl -fsSLo "$fonts_dir/MesloLGS NF Bold Italic.ttf" "$base_url/MesloLGS%20NF%20Bold%20Italic.ttf"
        fc-cache -fv >/dev/null 2>&1
    fi
    print_success "Meslo Nerd Font installed"
}

install_all_apps() {
    print_header "Apps"
    install_docker
    install_nerd_fonts
}

select_apps() {
    local items=("docker" "nerd-fonts (Meslo)")
    local funcs=(install_docker install_nerd_fonts)

    prompt_selection "Apps" "${items[@]}"

    if [[ ${#SELECTED_INDICES[@]} -eq 0 ]]; then
        print_skipped "apps"
        return 0
    fi

    print_header "Installing Apps"
    for idx in "${SELECTED_INDICES[@]}"; do
        ${funcs[$idx]}
    done
}
