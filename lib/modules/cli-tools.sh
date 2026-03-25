#!/bin/bash

install_fzf() { pkg_install "fzf"; }
install_fd() {
    if is_installed "fd"; then
        print_installed "fd"
        return 0
    fi
    case "$PACKAGE_MANAGER" in
        "brew") pkg_install "fd" ;;
        "apt") pkg_install "fd-find" "fdfind" ;;
    esac
}
install_bat() {
    if is_installed "bat"; then
        print_installed "bat"
        return 0
    fi
    case "$PACKAGE_MANAGER" in
        "brew") pkg_install "bat" ;;
        "apt") pkg_install "bat" "batcat" ;;
    esac
}
install_ripgrep() { pkg_install "ripgrep" "rg"; }
install_eza() {
    if is_installed "eza"; then
        print_installed "eza"
        return 0
    fi
    case "$PACKAGE_MANAGER" in
        "brew") pkg_install "eza" ;;
        "apt")
            print_step "Installing eza via apt repository..."
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
            sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
            sudo apt update -qq
            sudo apt install -y eza || print_warn "Failed to install eza"
            ;;
    esac
}
install_delta() {
    if is_installed "delta"; then
        print_installed "git-delta"
        return 0
    fi
    case "$PACKAGE_MANAGER" in
        "brew") pkg_install "git-delta" "delta" ;;
        "apt")
            print_step "Installing git-delta..."
            local version
            version=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
            curl -fsSL "https://github.com/dandavison/delta/releases/download/${version}/git-delta_${version}_amd64.deb" -o "/tmp/git-delta.deb"
            sudo dpkg -i "/tmp/git-delta.deb" || print_warn "Failed to install git-delta"
            rm -f "/tmp/git-delta.deb"
            ;;
    esac
}
install_lazygit() {
    if is_installed "lazygit"; then
        print_installed "lazygit"
        return 0
    fi
    case "$PACKAGE_MANAGER" in
        "brew") pkg_install "lazygit" ;;
        "apt")
            print_step "Installing lazygit..."
            local version
            version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
            curl -fsSL "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_Linux_x86_64.tar.gz" -o "/tmp/lazygit.tar.gz"
            tar -xzf "/tmp/lazygit.tar.gz" -C "/tmp"
            sudo install "/tmp/lazygit" "/usr/local/bin/lazygit"
            rm -f "/tmp/lazygit.tar.gz" "/tmp/lazygit"
            ;;
    esac
}
install_yazi() {
    if is_installed "yazi"; then
        print_installed "yazi"
        return 0
    fi
    case "$PACKAGE_MANAGER" in
        "brew") pkg_install "yazi" ;;
        "apt")
            print_step "Installing yazi..."
            local tarball="yazi-x86_64-unknown-linux-gnu"
            curl -fsSL "https://github.com/sxyazi/yazi/releases/latest/download/${tarball}.tar.gz" -o "/tmp/yazi.tar.gz"
            tar -xzf "/tmp/yazi.tar.gz" -C "/tmp"
            sudo install "/tmp/${tarball}/yazi" "/usr/local/bin/yazi"
            rm -rf "/tmp/yazi.tar.gz" "/tmp/${tarball}"
            ;;
    esac
}
install_tree() { pkg_install "tree"; }
install_htop() { pkg_install "htop"; }
install_jq() { pkg_install "jq"; }
install_wget() { pkg_install "wget"; }

install_all_cli_tools() {
    print_header "CLI Tools"
    install_fzf
    install_ripgrep
    install_fd
    install_bat
    install_eza
    install_delta
    install_lazygit
    install_yazi
    install_tree
    install_htop
    install_jq
    install_wget
}

select_cli_tools() {
    local items=("fzf" "ripgrep" "fd" "bat" "eza" "git-delta" "lazygit" "yazi" "tree" "htop" "jq" "wget")
    local funcs=(install_fzf install_ripgrep install_fd install_bat install_eza install_delta install_lazygit install_yazi install_tree install_htop install_jq install_wget)

    prompt_selection "CLI Tools" "${items[@]}"

    if [[ ${#SELECTED_INDICES[@]} -eq 0 ]]; then
        print_skipped "CLI tools"
        return 0
    fi

    print_header "Installing CLI Tools"
    for idx in "${SELECTED_INDICES[@]}"; do
        ${funcs[$idx]}
    done
}
