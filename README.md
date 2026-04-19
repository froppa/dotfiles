# Dotfiles — macOS Setup with chezmoi

[![ci](https://github.com/froppa/dotfiles/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/froppa/dotfiles/actions/workflows/ci.yml)

Minimal, modular dotfiles for macOS automated with chezmoi and Homebrew.

> **Work in progress — use at your own risk.**  
> These are my personal dotfiles, shared as-is for bootstrapping macOS and Linux setups.

## Quickstart

```bash
PERSONAL=true sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply froppa

WORK=true sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply froppa
```

1. (Optional) Run full setup:

```bash
git clone https://github.com/froppa/dotfiles.git ~/.local/share/chezmoi
cd ~/.local/share/chezmoi
./setup.sh
```

### Notes

- Homebrew package setup is handled by the repo's brewfile sources and `home/.chezmoiscripts/run_onchange_20-install-pkgs.sh`.
- VSCode extensions are declared in `home/.chezmoidata/vscode.yml`.
- VS Code user settings live in `home/dot_config/Code/User/`.
- Vim stays in `home/dot_vimrc`; Neovim lives in `home/dot_config/nvim/`.
- Core shell/git files such as `.zshrc`, `.zprofile`, `.exports`, `.functions`, `.gitconfig`, and `.vimrc` are meant to be chezmoi-managed.
- Keep machine-specific overrides in `.zshrc.local`, `.zprofile.local`, `.exports.local`, `.aliases.local`, `.functions.local`, `.zsh_completions.local`, and `.gitconfig.local`.
- Scripts run once on first setup.
- CI runs `test.sh`.

### Structure

- `home/` — chezmoi-managed home directory (dotfiles, configs, scripts)
- `home/.chezmoidata/` — layered YAML config data (base, macOS, features, local)
- `home/.chezmoiscripts/` — setup scripts (brew, packages, zsh, vim, neovim, vscode)
- `macos-scripts/` — macOS defaults and settings
- `scripts/` — helper scripts
- `setup.sh` — bootstrap entrypoint script

## Editors

- VS Code remains the stable editor-of-record and is managed in `home/dot_config/Code/User/` plus `home/.chezmoidata/vscode.yml`.
- Legacy Vim remains available through `home/dot_vimrc` and `home/.chezmoiscripts/run_once_21-install-vim.sh`.
- Neovim is a parallel setup in `home/dot_config/nvim/` with plugins bootstrapped by `home/.chezmoiscripts/run_once_22-install-neovim.sh`.

### Neovim quick start

1. Install `nvim` plus helper tools such as `fd`, `shfmt`, and `stylua`.
2. Apply the dotfiles as usual.
3. Open `nvim` once to finish plugin and parser setup if the bootstrap script has not already done it.
4. Run `:checkhealth` after first launch if something feels off.

### Neovim workflow defaults

- `Ctrl-P` — find files
- `<leader><leader>` — switch buffers
- `<leader>/` — live grep
- `<leader>e` or `-` — explorer-style file navigation
- `gd`, `gr`, `K`, `<leader>rn`, `<leader>ca` — LSP navigation and actions
- `[d`, `]d`, `<leader>cd` — diagnostics
- `<leader>f` — format buffer

The Neovim setup intentionally mirrors the current VS Code workflow for search, navigation, formatting, and diagnostics, while keeping modal editing and native Neovim ergonomics intact.

## Apply And Sync

Apply the current repo to this machine:

```bash
chezmoi init --apply "$(pwd)"
```

Apply changes from an already-initialized chezmoi source:

```bash
chezmoi apply -v
```

Check what will change:

```bash
chezmoi status
chezmoi diff
```

Edit a managed file and apply it immediately:

```bash
chezmoi edit --apply ~/.zshrc
chezmoi edit --apply ~/.aliases
```

Sync the source repo on a machine where chezmoi is already initialized:

```bash
cd "$(chezmoi source-path)"
git pull --ff-only
chezmoi apply -v
```

Local-only files such as `.zshrc.local`, `.exports.local`, and `.gitconfig.local` are intentionally ignored by chezmoi and should be created directly on each machine.

---

## To Do

- [ ] Encryption: <https://www.chezmoi.io/user-guide/encryption/>
  - SSH Keys etc `chezmoi add --encrypt ~/.ssh/id_rsa`.
- [ ] MacOS Scripts

---

Made for easy, repeatable environment setup with modular control.
Fork it, tweak it, make it yours.
