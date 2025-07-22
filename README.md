# Cross-Platform Dev Environment Setup

Automated setup scripts for macOS and Ubuntu Linux development environments with integrated dotfiles management.

## Quick Start

```bash
# Clone this repository
git clone https://github.com/erinjkim43/dev-setup-automation
cd dev-setup-automation

# Run the main setup script
./bootstrap.sh

# Optionally install additional tools
./optional-tools.sh
```

## What It Does

### Core Setup (`bootstrap.sh`)
- Detects your operating system (macOS/Ubuntu)
- Installs appropriate package manager (Homebrew on macOS)
- Installs essential development tools:
  - Git, Neovim, tmux, zsh
  - WezTerm (terminal emulator)
  - Node.js, Python, Rust
- Configures SSH keys for GitHub
- Installs Meslo Nerd Font
- Sets up Tmux Plugin Manager (TPM)
- Clones and applies dotfiles using yadm
- Sets zsh as default shell

### Optional Tools (`optional-tools.sh`)
Interactive installer for:
- Docker
- Programming languages (Rust, Go, Ruby)
- CLI tools (fzf, ripgrep, fd, bat, eza, lazygit, yazi, etc.)

## Supported Platforms

### macOS
- Uses Homebrew for package management
- Installs Homebrew automatically if not present

### Ubuntu/Debian Linux
- Uses `apt` package manager
- Includes Flatpak for additional applications

## Prerequisites

- Bash shell
- Internet connection
- sudo access (for Linux)

## Usage

### First Time Setup
```bash
./bootstrap.sh
```

### Adding Optional Tools
```bash
./optional-tools.sh
```

### Updating Dotfiles
```bash
yadm pull
```

### Customizing Dotfiles
Dotfiles are managed in a separate repository. To customize:
- Fork or modify the dotfiles repository
- Update `REPO_URL` in `lib/dotfiles.sh` to point to your repository
- Use yadm's alternate files for platform-specific configurations

## Features

### YADM Dotfiles Integration
- **Powerful dotfile management**: Uses yadm for advanced dotfile features
- **Platform-specific configs**: Supports OS-specific configurations with alternate files
- **External repository**: Dotfiles managed in separate repository for flexibility
- **Automatic updates**: Easy updates with `yadm pull`

### Modular Architecture
- **lib/system.sh**: OS detection and system setup
- **lib/packages.sh**: Package installation and font management
- **lib/dotfiles.sh**: Configuration management and shell setup
- **lib/utils.sh**: Neovim and utility functions

### Security Features
- Root user detection and warnings
- SSH key generation with GitHub integration
- Safe error handling throughout setup process

## Customization

### Adding Packages
Edit package arrays in:
- `lib/packages.sh` for core packages
- `optional-tools.sh` for optional tools

### Modifying Configurations
- Edit files in your dotfiles repository
- Use `yadm status` and `yadm commit` to track changes
- Push changes to your dotfiles repository

## Troubleshooting

### Package Installation Fails
- Check internet connection
- Ensure you have sudo access (Linux)
- Verify package names for your distribution

### Dotfiles Not Applied
- Check yadm status: `yadm status`
- Manually pull changes: `yadm pull`
- Check repository URL is correct in `lib/dotfiles.sh`

### Shell Not Changed
- Restart terminal after running bootstrap
- Manually change shell: `chsh -s $(which zsh)`

### SSH Setup Issues
- Ensure you've added the generated key to GitHub
- Test connection: `ssh -T git@github.com`

## File Structure

```
dev-setup-automation/
├── lib/                     # Modular functionality
│   ├── system.sh           # OS detection & root checks
│   ├── packages.sh         # Package installation
│   ├── dotfiles.sh         # Configuration management
│   └── utils.sh            # Utilities & Neovim setup
├── bootstrap.sh           # Main setup script
├── optional-tools.sh      # Optional tools installer
├── CLAUDE.md             # Development documentation
└── README.md             # This file
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on target platforms
5. Submit a pull request

## License

This project is open source and available under the MIT License.