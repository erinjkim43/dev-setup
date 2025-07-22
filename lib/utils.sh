#!/bin/bash

setup_neovim_headless() {
    echo "🔧 Pre-installing Neovim plugins and LSP servers..."
    
    sleep 2
    
    if ! command -v nvim >/dev/null 2>&1; then
        echo "⚠️ Neovim not found, skipping plugin setup"
        return
    fi
    
    echo "Installing Lazy.nvim plugins..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || echo "⚠️ Lazy plugin sync had issues (this is normal on first run)"
    
    echo "Installing common LSP servers via Mason..."
    LSP_SERVERS=(
        "lua_ls"
        "typescript-language-server"
        "intelephense"
        "tailwindcss-language-server"
        "rust-analyzer" 
        "pyright"
        "bash-language-server"
        "json-lsp"
        "yaml-language-server"
        "marksman"
        "prettier"
        "stylua"
        "pint"
        "isort"
        "black"
        "eslint_d"
        "shfmt"
    )
    
    for server in "${LSP_SERVERS[@]}"; do
        echo "Installing $server..."
        nvim --headless -c "MasonInstall $server" -c qall 2>/dev/null || echo "⚠️ Failed to install $server (may not be available)"
    done
    
    echo "✅ Neovim setup complete - plugins and LSP servers pre-installed"
}