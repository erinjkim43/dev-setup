# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a cross-platform development environment setup automation repository that provides modular bash scripts to install and configure development tools across macOS and Ubuntu Linux. The repository focuses on automating the tedious setup process for a consistent development environment with integrated dotfiles management.

## Key Scripts

### Main Setup Script
- `./bootstrap.sh` - Primary setup script that installs core development tools and configures the environment
- `./optional-tools.sh` - Interactive installer for additional/optional development tools

### Script Execution
Both scripts are executable bash files that should be run directly:
```bash
./bootstrap.sh      # Core setup
./optional-tools.sh # Optional tools
```

No build process, compilation, or package management commands are needed - these are standalone bash scripts.

## Architecture

### Modular Design
The repository is organized into distinct modules for better maintainability:

#### Library Modules (`lib/`)
- `lib/system.sh` - OS detection, root checks, package manager setup
- `lib/packages.sh` - Core package installation and Nerd Font setup
- `lib/dotfiles.sh` - Configuration file management and shell setup
- `lib/utils.sh` - Neovim headless setup utilities

#### Configuration Files (`configs/`)
- `configs/zshrc` - Zsh shell configuration with Oh My Zsh and Powerlevel10k
- `configs/tmux.conf` - Tmux configuration with TPM plugins
- `configs/wezterm.lua` - WezTerm terminal emulator configuration

### Cross-Platform Design
The scripts use OS detection to handle platform-specific package management:
- **macOS**: Uses Homebrew (`brew`)
- **Ubuntu/Debian**: Uses `apt` package manager

### Core Components

#### bootstrap.sh Functions
Main script that sources all library modules and orchestrates the setup process:
- Sources all `lib/*.sh` modules
- Calls functions in logical order for complete environment setup
- Handles dotfile installation directly from local `configs/` directory

#### lib/system.sh Functions
- `check_root()` - Security check to prevent running as root user
- `detect_os()` - OS and package manager detection (macOS/Ubuntu only)
- `install_package_manager()` - Installs Homebrew on macOS if needed

#### lib/packages.sh Functions
- `install_core_packages()` - Installs core development packages based on detected OS
- `install_nerd_fonts()` - Installs Meslo Nerd Font for terminal

#### lib/dotfiles.sh Functions
- `install_dotfiles()` - Copies configuration files from `configs/` to home directory
- `setup_ssh()` - Generates SSH keys and guides GitHub setup
- `setup_tpm()` - Installs Tmux Plugin Manager
- `configure_shell()` - Sets zsh as default shell

#### lib/utils.sh Functions
- `setup_neovim_headless()` - Pre-installs Neovim plugins and LSP servers

#### optional-tools.sh Functions
- `install_docker()` - Platform-specific Docker installation
- `install_rust()` - Rust toolchain via rustup
- `install_go()` - Go programming language
- `install_ruby()` - Ruby programming language with rbenv
- `install_dev_tools()` - CLI utilities (fzf, ripgrep, bat, eza, yazi, etc.)
- `show_menu()` - Interactive menu system

### Dotfiles Management

The repository now includes dotfiles directly in the `configs/` directory instead of using yadm:
- **Direct file management**: Configuration files are copied directly to their target locations
- **Version controlled**: All configs are part of this repository
- **No external dependencies**: Eliminates yadm dependency for simpler setup

### Key Configuration

#### Customization Points
- Modify package arrays in `lib/packages.sh` for different core packages
- Update tool lists in `optional-tools.sh` for different optional tools
- Edit configuration files in `configs/` directory to customize dotfiles
- Font selection in `install_nerd_fonts()` - Currently uses Meslo, can be changed

#### Security Features
- Root user detection and warning
- SSH key generation with user prompts
- GitHub integration guidance
- Package installation error handling

## Testing and Validation

No automated test suite exists. Manual testing approach:
- Test on target platforms (macOS, Ubuntu)
- Verify package installations complete successfully
- Check dotfiles are properly copied to home directory
- Confirm shell changes take effect
- Validate SSH key generation and GitHub connectivity

## Development Notes

- Scripts use `set -e` for fail-fast behavior
- Error handling via `|| echo "⚠️ Failed to install $package"` pattern
- Interactive prompts for user input (email for SSH, GitHub setup)
- Platform-specific font installation methods
- Modular design allows easy extension and maintenance
- Graceful fallback from SSH to HTTPS for git operations