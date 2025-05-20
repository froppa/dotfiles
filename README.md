# Dotfiles — macOS Setup with chezmoi

[![ci](https://github.com/froppa/dotfiles/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/froppa/dotfiles/actions/workflows/ci.yml)

Minimal, modular dotfiles for macOS automated with chezmoi and Homebrew.

> **Work in progress — use at your own risk.**  
> These are my personal dotfiles, shared as-is for bootstrapping macOS and Linux setups.

## Quickstart

1. Install chezmoi:

```bash
brew install chezmoi
```

2. Bootstrap your system (if public, GH username):

```bash
$GITHUB_USERNAME=froppa chezmoi init --apply $GITHUB_USERNAME
```

3. (Optional) Run full setup:

```bash
git clone https://github.com/froppa/dotfiles.git ~/.local/share/chezmoi
cd ~/.local/share/chezmoi
./setup.sh
```

### Notes

- Homebrew packages and taps are declared in `home/.chezmoidata/brewfile.yml`.
- VSCode extensions are declared in `home/.chezmoidata/vscode.yml`.
- Scripts run once on first setup.
- CI runs `test.sh`.

### Structure

- `home/` — chezmoi-managed home directory (dotfiles, configs, scripts)
- `home/.chezmoidata/` — layered YAML config data (base, macOS, features, local)
- `home/.chezmoiscripts/` — setup scripts (brew, packages, zsh, vim, vscode)
- `macos-scripts/` — macOS defaults and settings
- `scripts/` — helper scripts
- `setup.sh` — bootstrap entrypoint script

---

## To Do

- [ ] Encryption: <https://www.chezmoi.io/user-guide/encryption/>
  - SSH Keys etc `chezmoi add --encrypt ~/.ssh/id_rsa`.
- [ ] MacOS Scripts

---

Made for easy, repeatable environment setup with modular control.
Fork it, tweak it, make it yours.
