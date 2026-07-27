# Dotfiles — macOS Setup with chezmoi

[![ci](https://github.com/froppa/dotfiles/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/froppa/dotfiles/actions/workflows/ci.yml)

Minimal, modular dotfiles for macOS, automated with chezmoi and Homebrew.
Most shell configuration also works on Linux; package installation and
`macos-scripts/` are macOS-only.

> **Work in progress — use at your own risk.**
> These are my personal dotfiles, shared as-is.

## Prerequisites

- [chezmoi](https://www.chezmoi.io/) (installed automatically by the quickstart and `init.sh`)
- To decrypt the age-encrypted files (SSH private key, Zed settings), the age
  identity must exist at `~/.config/sops/age/keys.txt` **before** applying.
  Without it, `chezmoi apply` fails on the encrypted entries.

## Quickstart

Pick the matching profile — it selects the Homebrew package set:

```bash
# Personal machine
PERSONAL=true sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply froppa

# Work machine
WORK=true sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply froppa
```

For a full bootstrap (Homebrew, packages, editor plugins) clone and run
`init.sh` instead:

```bash
git clone https://github.com/froppa/dotfiles.git ~/.local/share/chezmoi
cd ~/.local/share/chezmoi
./init.sh           # add --macos to also apply macOS system defaults
```

`./init.sh` accepts `--name`, `--email`, and `--signing-key` for git identity
(stored by chezmoi on first use) and `--macos` to run `macos-scripts/` after
applying. Run `./init.sh --help` for details.

## Daily usage

```bash
chezmoi apply -v                  # apply changes from the source repo
chezmoi status && chezmoi diff    # preview what would change
chezmoi edit --apply ~/.zshrc     # edit a managed file and apply immediately

cd "$(chezmoi source-path)"       # sync source repo, then apply
git pull --ff-only
chezmoi apply -v
```

Keep machine-specific overrides in `*.local` files, created directly on each
machine and intentionally ignored by chezmoi: `.zshrc.local`,
`.zprofile.local`, `.exports.local`, `.aliases.local`, `.functions.local`,
`.zsh_completions.local`, and `.gitconfig.local`.

## What's managed where

- Homebrew packages — `home/.chezmoidata/40-packages.yml`, installed by
  `home/.chezmoiscripts/run_onchange_20-install-pkgs.sh.tmpl` (re-runs when
  the data changes)
- Language runtimes (node, python, go, ruby, pnpm, yarn) — mise via
  `home/dot_config/mise/config.toml`
- VS Code extensions — `home/.chezmoidata/vscode.yml`
- Raycast Script Commands — `home/dot_config/raycast/scripts/`, deployed to
  `~/.config/raycast/scripts/` (kept out of `~/.config/raycast/` itself, which
  Raycast uses for its own extension data). On a new machine, add the folder
  once via Raycast → Settings → Extensions → Script Commands → Add Script
  Directory.

## Structure

- `home/` — chezmoi-managed home directory (dotfiles, configs, scripts)
- `home/.chezmoidata/` — layered YAML config data (features, packages, vscode, local)
- `home/.chezmoiscripts/` — setup scripts (brew, packages, vim, neovim, vscode)
- `macos-scripts/` — macOS system defaults (see below)
- `scripts/` — helper scripts (ssh-keygen, iterm2 prefs export)
- `init.sh` — bootstrap entrypoint

## macOS defaults

```bash
macos-scripts/macos-defaults.sh --audit   # report drift without changing anything
macos-scripts/macos-defaults.sh           # apply all sections
macos-scripts/macos-defaults.sh --update  # also install macOS software updates
```

## Editors

- VS Code is the stable editor-of-record, managed in `home/dot_config/Code/User/`
  plus `home/.chezmoidata/vscode.yml`.
- Legacy Vim stays available through `home/dot_vimrc` and
  `home/.chezmoiscripts/run_once_after_21-install-vim.sh`.
- Neovim is a parallel LazyVim-based setup in `home/dot_config/nvim/`, with
  plugins bootstrapped by `home/.chezmoiscripts/run_once_after_22-install-neovim.sh`.
  Open `nvim` once after applying to finish Mason and tree-sitter installs,
  and run `:LazyHealth` if something feels off. It mirrors the VS Code
  workflow for search, navigation, formatting, and diagnostics — keybindings
  are documented in [docs/nvim-cheat-sheet.md](docs/nvim-cheat-sheet.md).

## Testing

CI runs `./test.sh` (shellcheck, chezmoi template render, dry-run apply).
It also runs locally; requires `shellcheck` and `chezmoi` on `PATH`.
