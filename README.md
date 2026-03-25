# Cross-Platform Dev Environment Setup

Automated setup for macOS and Ubuntu Linux development environments. A single interactive script lets you pick exactly what to install, or use CLI flags for unattended setup.

## Quick Start

```bash
git clone https://github.com/erinjkim43/dev-setup-automation
cd dev-setup-automation

# Interactive mode - pick what you want
./setup.sh

# Or install everything at once
./setup.sh --all
```

## Usage

### Interactive Mode

Run `./setup.sh` with no arguments to get an interactive menu:

```
Categories:
  1) Core packages (git, neovim, tmux, zsh, node, python)
  2) Languages (rust, go, ruby)
  3) CLI tools (fzf, ripgrep, fd, bat, delta, lazygit, eza, yazi...)
  4) Apps (docker, nerd-fonts)
  5) Configuration (ssh, dotfiles, tpm, shell, neovim plugins)
  a) All of the above
  q) Quit

Select categories (comma-separated, e.g. 1,3,5):
```

After selecting a category, you can pick individual tools within it.

### Non-Interactive Mode

Use flags to install specific categories without prompts:

```bash
./setup.sh --all         # Install everything
./setup.sh --core        # Core packages only
./setup.sh --langs       # Programming languages only
./setup.sh --cli         # CLI tools only
./setup.sh --apps        # Apps only
./setup.sh --config      # Configuration setup only
./setup.sh -h            # Show help
```

## What Gets Installed

| Category | Tools |
|----------|-------|
| **Core** | git, neovim, tmux, zsh, node, python |
| **Languages** | rust (via rustup), go, ruby (with rbenv) |
| **CLI Tools** | fzf, ripgrep, fd, bat, eza, git-delta, lazygit, yazi, tree, htop, jq, wget |
| **Apps** | docker, Meslo Nerd Font |
| **Config** | SSH keys, dotfiles (yadm), TPM, zsh as default shell, Neovim plugins + LSP servers |

## Supported Platforms

- **macOS** -- uses Homebrew (installed automatically if missing)
- **Ubuntu/Debian Linux** -- uses apt

## Prerequisites

- Bash shell
- Internet connection
- sudo access (for Linux)

## File Structure

```
dev-setup-automation/
├── setup.sh               # Main entrypoint (interactive + CLI flags)
├── lib/
│   ├── ui.sh              # Shared UI helpers (colors, menus, prompts)
│   ├── system.sh          # OS detection & root checks
│   └── modules/
│       ├── core.sh        # Core packages (git, neovim, tmux, zsh, node, python)
│       ├── languages.sh   # Languages (rust, go, ruby)
│       ├── cli-tools.sh   # CLI tools (fzf, ripgrep, fd, bat, eza, delta, lazygit, yazi...)
│       ├── apps.sh        # Apps (docker, nerd-fonts)
│       └── config.sh      # Config (ssh, dotfiles/yadm, tpm, shell, neovim plugins)
├── CLAUDE.md
└── README.md
```

## Customization

- **Add/remove packages**: Edit the relevant module in `lib/modules/`
- **Change fonts**: Modify `install_nerd_fonts()` in `lib/modules/apps.sh`
- **Dotfiles repo**: Update `DOTS_REPO` and `DOTS_SSH` in `lib/modules/config.sh`
- **UI tweaks**: Edit colors and prompts in `lib/ui.sh`

## Troubleshooting

### Package installation fails
- Check your internet connection
- On Linux, ensure you have sudo access
- Run the script again -- already-installed tools are detected and skipped

### Shell not changed to zsh
- Restart your terminal after setup
- Or manually run: `chsh -s $(which zsh)`

### SSH key not working with GitHub
- Verify the key was added at https://github.com/settings/keys
- Test with: `ssh -T git@github.com`

### Neovim plugin errors on first run
- This is normal -- plugins finish installing on first launch
- Run `:Lazy sync` inside Neovim to retry

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on target platforms (macOS, Ubuntu)
5. Submit a pull request

## License

This project is open source and available under the MIT License.
