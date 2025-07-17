# Cross-Platform Dev Environment Setup

Automated setup scripts for macOS and Linux development environments.

## Quick Start

```bash
# Clone this repository
git clone <your-repo-url>
cd dev-setup-automation

# Run the main setup script
./bootstrap.sh

# Optionally install additional tools
./optional-tools.sh
```

## What It Does

### Core Setup (`bootstrap.sh`)
- Detects your operating system (macOS/Linux)
- Installs appropriate package manager (Homebrew on macOS)
- Installs essential development tools:
  - Git, yadm, Neovim, tmux, zsh
  - WezTerm (terminal emulator)
  - Node.js, Python, Rust
- Clones and applies your dotfiles using yadm
- Sets zsh as default shell

### Optional Tools (`optional-tools.sh`)
Interactive installer for:
- Docker
- Programming languages (Rust, Go, Ruby)
- CLI tools (fzf, ripgrep, fd, bat, exa, lazygit, etc.)

## Supported Platforms

### macOS
- Uses Homebrew for package management
- Installs Homebrew automatically if not present

### Linux
- **Ubuntu/Debian**: Uses `apt`
- **Fedora/RHEL**: Uses `dnf`
- **Arch Linux**: Uses `pacman`

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

## Customization

Edit the package lists in each script to match your preferences:

- Core packages in `bootstrap.sh`
- Optional packages in `optional-tools.sh`
- Update `REPO_URL` in `bootstrap.sh` to point to your dotfiles repository

## Troubleshooting

### Package Installation Fails
- Check internet connection
- Ensure you have sudo access (Linux)
- Verify package names for your distribution

### Dotfiles Not Applied
- Check that yadm installed correctly: `yadm status`
- Manually pull changes: `yadm pull`
- Check repository URL is correct

### Shell Not Changed
- Restart terminal after running bootstrap
- Manually change shell: `chsh -s $(which zsh)`

## File Structure

```
dev-setup-automation/
├── bootstrap.sh          # Main setup script
├── optional-tools.sh     # Optional tools installer
└── README.md            # This file
```