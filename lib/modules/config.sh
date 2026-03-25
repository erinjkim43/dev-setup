#!/bin/bash

DOTS_REPO="https://github.com/erinjkim43/dots.git"
DOTS_SSH="git@github.com:erinjkim43/dots.git"

setup_ssh() {
    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        print_installed "SSH key"
        ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null || true
        return 0
    fi

    print_step "Generating SSH key..."
    read -rp "Enter your email for SSH key: " email
    ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""

    eval "$(ssh-agent -s)" >/dev/null
    ssh-add "$HOME/.ssh/id_ed25519"

    echo ""
    echo -e "${BOLD}Your SSH public key:${NC}"
    echo "---"
    cat "$HOME/.ssh/id_ed25519.pub"
    echo "---"
    echo ""
    echo "Add it at: https://github.com/settings/ssh/new"
    echo ""
    read -rp "Press Enter after adding the key to GitHub..."

    ssh -T git@github.com 2>&1 || true
    print_success "SSH key configured"
}

setup_dotfiles() {
    print_step "Setting up dotfiles with yadm..."

    if ! is_installed "yadm"; then
        pkg_install "yadm"
    fi

    if [[ -d "$HOME/.config/yadm" ]]; then
        print_installed "dotfiles"
        yadm pull 2>/dev/null || true
        return 0
    fi

    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        yadm clone "$DOTS_SSH"
    else
        yadm clone "$DOTS_REPO"
    fi
    print_success "dotfiles installed"
}

setup_tpm() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ -d "$tpm_dir" ]]; then
        print_installed "TPM (Tmux Plugin Manager)"
        return 0
    fi
    print_step "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
    print_success "TPM installed"
}

configure_default_shell() {
    if [[ "$SHELL" == *"zsh"* ]]; then
        print_installed "zsh as default shell"
        return 0
    fi
    local zsh_path
    zsh_path=$(which zsh 2>/dev/null)
    if [[ -z "$zsh_path" ]]; then
        print_warn "zsh not found, skipping shell change"
        return 1
    fi
    print_step "Setting zsh as default shell..."
    chsh -s "$zsh_path"
    print_success "zsh set as default shell"
}

setup_neovim_plugins() {
    if ! is_installed "nvim"; then
        print_warn "Neovim not found, skipping plugin setup"
        return 0
    fi

    print_step "Pre-installing Neovim plugins..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || print_warn "Lazy plugin sync had issues (normal on first run)"

    print_step "Installing LSP servers via Mason..."
    local servers=(
        "lua_ls"
        "typescript-language-server"
        "tailwindcss-language-server"
        "rust-analyzer"
        "pyright"
        "bash-language-server"
        "json-lsp"
        "yaml-language-server"
        "marksman"
        "prettier"
        "stylua"
        "isort"
        "black"
        "eslint_d"
        "shfmt"
    )

    for server in "${servers[@]}"; do
        nvim --headless -c "MasonInstall $server" -c qall 2>/dev/null || print_warn "Failed to install $server"
    done
    print_success "Neovim plugins installed"
}

install_all_config() {
    print_header "Configuration"
    setup_ssh
    setup_dotfiles
    setup_tpm
    configure_default_shell
    setup_neovim_plugins
}

select_config() {
    local items=("ssh-keys" "dotfiles (yadm)" "tmux-plugin-manager" "zsh-as-default-shell" "neovim-plugins")
    local funcs=(setup_ssh setup_dotfiles setup_tpm configure_default_shell setup_neovim_plugins)

    prompt_selection "Configuration" "${items[@]}"

    if [[ ${#SELECTED_INDICES[@]} -eq 0 ]]; then
        print_skipped "configuration"
        return 0
    fi

    print_header "Setting Up Configuration"
    for idx in "${SELECTED_INDICES[@]}"; do
        ${funcs[$idx]}
    done
}
