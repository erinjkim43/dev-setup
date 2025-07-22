#!/bin/bash

REPO_URL="https://github.com/erinjkim43/dots.git"
DOTFILES_DIR="$HOME/.config/yadm"

install_dotfiles() {
    echo "🔧 Setting up dotfiles with yadm..."
    
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        echo "Cloning dotfiles repository..."
        
        # Try SSH first, fall back to HTTPS
        SSH_REPO_URL="git@github.com:erinjkim43/dots.git"
        if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
            echo "Using SSH to clone repository..."
            yadm clone "$SSH_REPO_URL"
        else
            echo "SSH not configured, using HTTPS..."
            yadm clone "$REPO_URL"
        fi
    else
        echo "✅ Dotfiles already cloned"
        yadm pull
    fi
    
    echo "Applying dotfile configurations..."
    yadm status
    
    echo "✅ Dotfiles installed"
}

setup_ssh() {
    echo "🔑 Setting up SSH authentication..."
    
    if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        echo "Generating SSH key..."
        read -p "Enter your email for SSH key: " email
        ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""
        
        echo "Starting SSH agent..."
        eval "$(ssh-agent -s)"
        ssh-add "$HOME/.ssh/id_ed25519"
        
        echo ""
        echo "📋 Your SSH public key (copy this to GitHub):"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        cat "$HOME/.ssh/id_ed25519.pub"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "📖 Go to: https://github.com/settings/ssh/new"
        echo "1. Paste the key above"
        echo "2. Give it a title (e.g., 'Dev Machine $(date +%Y-%m-%d)')"
        echo "3. Click 'Add SSH key'"
        echo ""
        read -p "Press Enter after adding the SSH key to GitHub..."
        
        echo "Testing SSH connection..."
        ssh -T git@github.com || echo "⚠️ SSH test failed, but this might be normal"
    else
        echo "✅ SSH key already exists"
        ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null || true
    fi
}

setup_tpm() {
    echo "🔧 Setting up TPM (Tmux Plugin Manager)..."
    
    TPM_DIR="$HOME/.tmux/plugins/tpm"
    if [[ ! -d "$TPM_DIR" ]]; then
        echo "Installing TPM..."
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
        echo "✅ TPM installed - plugins will be installed when tmux starts"
    else
        echo "✅ TPM already installed"
    fi
}

configure_shell() {
    echo "🐚 Configuring shell..."
    
    if [[ "$SHELL" != *"zsh"* ]]; then
        echo "Setting zsh as default shell..."
        ZSH_PATH=$(which zsh)
        if [[ -n "$ZSH_PATH" ]]; then
            chsh -s "$ZSH_PATH"
        else
            echo "⚠️ zsh not found in PATH"
        fi
    else
        echo "✅ zsh already set as default shell"
    fi
}