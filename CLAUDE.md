# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a cross-platform development environment setup automation repository that provides modular bash scripts to install and configure development tools across macOS and Ubuntu Linux. The repository focuses on automating the tedious setup process for a consistent development environment with integrated dotfiles management via yadm.

## Entry Point

### setup.sh
Single entry point for the entire setup process. Supports both interactive and non-interactive modes.

```bash
./setup.sh              # Interactive mode (category menu with per-item selection)
./setup.sh --all        # Install everything non-interactively
./setup.sh --core       # Install core packages only
./setup.sh --langs      # Install programming languages only
./setup.sh --cli        # Install CLI tools only
./setup.sh --apps       # Install apps only
./setup.sh --config     # Run configuration setup only
./setup.sh -h, --help   # Show help message
```

No build process, compilation, or package management commands are needed -- these are standalone bash scripts.

## Architecture

### File Structure

```
setup.sh                      # Main entry point
lib/
  ui.sh                       # Shared UI helpers and utilities
  system.sh                   # OS detection, root checks, package manager setup
  modules/
    core.sh                   # Core development packages
    languages.sh              # Programming languages
    cli-tools.sh              # CLI utilities
    apps.sh                   # Applications and fonts
    config.sh                 # Environment configuration and dotfiles
```

### Cross-Platform Design
The scripts use OS detection to handle platform-specific package management:
- **macOS**: Uses Homebrew (`brew`)
- **Ubuntu/Debian**: Uses `apt` package manager

### Module Pattern

Each module in `lib/modules/` follows a consistent pattern:
- Individual `install_<tool>()` functions for each tool
- `install_all_<category>()` function that installs everything in the module (used by `--flag` mode)
- `select_<category>()` function that presents an interactive picker (used in interactive mode)

The interactive picker is powered by `prompt_selection()` from `lib/ui.sh`, which lets users choose items by comma-separated numbers, `a` for all, or `q` to skip.

### Core Components

#### setup.sh
Main script that sources all library modules and orchestrates the setup flow:
- Sources `lib/ui.sh`, `lib/system.sh`, and all `lib/modules/*.sh`
- Runs `check_root`, `detect_os`, and `install_package_manager` on every invocation
- Routes to `install_all_*()` functions for flag-based invocation, or presents the interactive category menu

#### lib/ui.sh Functions
Shared UI helpers used by all modules:
- `print_header()`, `print_step()`, `print_success()`, `print_warn()`, `print_error()` - Colored output helpers
- `print_installed()`, `print_skipped()` - Status indicators for already-installed or skipped items
- `is_installed()` - Check if a command exists on the system
- `pkg_install()` - Install a package with the detected package manager, with already-installed check
- `cask_install()` - Install a Homebrew cask (macOS only)
- `prompt_selection()` - Interactive numbered list picker with comma-separated selection
- `confirm()` - Yes/no prompt

#### lib/system.sh Functions
- `check_root()` - Warns if running as root, offers to exit
- `detect_os()` - Sets `$OS` and `$PACKAGE_MANAGER` globals (macOS/Ubuntu only)
- `install_package_manager()` - Installs Homebrew on macOS if needed

#### lib/modules/core.sh Functions
- `install_git()`, `install_neovim()`, `install_tmux()`, `install_zsh()`, `install_node()`, `install_python()`
- `install_all_core()` - Installs all core packages
- `select_core_packages()` - Interactive picker for core packages

#### lib/modules/languages.sh Functions
- `install_rust()` - Rust toolchain via rustup
- `install_go()`, `install_ruby()` - Language installation with rbenv for Ruby
- `install_all_languages()` - Installs all languages
- `select_languages()` - Interactive picker for languages

#### lib/modules/cli-tools.sh Functions
- `install_fzf()`, `install_ripgrep()`, `install_fd()`, `install_bat()`, `install_eza()`, `install_delta()`, `install_lazygit()`, `install_yazi()`, `install_tree()`, `install_htop()`, `install_jq()`, `install_wget()`
- `install_all_cli_tools()` - Installs all CLI tools
- `select_cli_tools()` - Interactive picker for CLI tools

#### lib/modules/apps.sh Functions
- `install_docker()` - Platform-specific Docker installation
- `install_nerd_fonts()` - Installs Meslo Nerd Font for terminal
- `install_all_apps()` - Installs all apps
- `select_apps()` - Interactive picker for apps

#### lib/modules/config.sh Functions
- `setup_ssh()` - Generates SSH key and guides GitHub setup
- `setup_dotfiles()` - Clones dotfiles repo via yadm (SSH with HTTPS fallback)
- `setup_tpm()` - Installs Tmux Plugin Manager
- `configure_default_shell()` - Sets zsh as default shell
- `setup_neovim_plugins()` - Pre-installs Neovim plugins via Lazy and LSP servers via Mason
- `install_all_config()` - Runs all configuration steps
- `select_config()` - Interactive picker for configuration steps

### Dotfiles Management

Dotfiles are managed via yadm, cloning from an external repository:
- **yadm-based**: `setup_dotfiles()` installs yadm and clones the dotfiles repo
- **SSH-preferred**: Tries SSH clone first, falls back to HTTPS if SSH is not set up
- **External repo**: Dotfiles live in a separate repository, not in this one

### Key Configuration

#### Customization Points
- Add new tools by creating an `install_<tool>()` function in the appropriate module and adding it to the module's items/funcs arrays
- Modify LSP server list in `setup_neovim_plugins()` within `lib/modules/config.sh`
- Font selection in `install_nerd_fonts()` -- currently uses Meslo, can be changed
- Dotfiles repo URL at the top of `lib/modules/config.sh`

#### Security Features
- Root user detection and warning
- SSH key generation with user prompts
- GitHub integration guidance
- Package installation error handling with `print_warn` on failure

## Testing and Validation

No automated test suite exists. Manual testing approach:
- Test on target platforms (macOS, Ubuntu)
- Verify package installations complete successfully
- Check dotfiles are properly cloned via yadm
- Confirm shell changes take effect
- Validate SSH key generation and GitHub connectivity
- Test both interactive mode and each `--flag` independently

## Development Notes

- Scripts use `set -e` for fail-fast behavior
- Error handling via `|| print_warn "Failed to install $name"` pattern
- All modules depend on globals set by `lib/system.sh` (`$OS`, `$PACKAGE_MANAGER`) and helpers from `lib/ui.sh`
- Interactive prompts for user input (email for SSH, GitHub setup, tool selection)
- Platform-specific installation methods (brew vs apt, cask for macOS-only apps, manual downloads for tools not in apt)
- Modular design allows easy extension -- add a new module file and source it in `setup.sh`
