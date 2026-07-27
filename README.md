# Dotfiles — macOS Setup with chezmoi

[![ci](https://github.com/froppa/dotfiles/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/froppa/dotfiles/actions/workflows/ci.yml)
[![managed with chezmoi](https://img.shields.io/badge/managed%20with-chezmoi-6e4c1e)](https://www.chezmoi.io/)
![platform](https://img.shields.io/badge/platform-macOS%20%2B%20Linux-lightgrey)

Minimal, modular dotfiles for macOS, automated with chezmoi and Homebrew.
Most shell configuration also works on Linux; packages and `macos-scripts/`
are macOS-only.

> ⚠️ **Work in progress — use at your own risk.** These are my personal
> dotfiles, shared as-is.

## Prerequisites

🔑 The age identity must exist at `~/.config/sops/age/keys.txt` **before**
applying — without it, `chezmoi apply` fails on the encrypted files (SSH
private key, Zed settings).

## Quickstart

```bash
# Personal machine
PERSONAL=true sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply froppa

# Work machine (different Homebrew package set)
WORK=true sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply froppa
```

For a full bootstrap (Homebrew, packages, editor plugins):

```bash
git clone https://github.com/froppa/dotfiles.git ~/.local/share/chezmoi
cd ~/.local/share/chezmoi
./init.sh    # options: --name --email --signing-key --macos (see --help)
```

## Daily usage

```bash
chezmoi apply -v               # apply changes from the source repo
chezmoi update -v              # pull the source repo and apply
chezmoi diff                   # preview what would change
chezmoi edit --apply ~/.zshrc  # edit a managed file and apply immediately
```

Keep machine-specific overrides in `*.local` files, created directly on each
machine and ignored by chezmoi: `.zshrc.local`, `.zprofile.local`,
`.exports.local`, `.aliases.local`, `.functions.local`,
`.zsh_completions.local`, `.gitconfig.local`.

## What's managed where

- Homebrew packages — `home/.chezmoidata/40-packages.yml`, installed by
  `home/.chezmoiscripts/run_onchange_20-install-pkgs.sh.tmpl` (re-runs when
  the data changes)
- Language runtimes (node, python, go, ruby, pnpm, yarn) — mise via
  `home/dot_config/mise/config.toml`
- VS Code extensions — `home/.chezmoidata/vscode.yml`
- Raycast Script Commands — `home/dot_config/raycast/scripts/`, deployed to
  `~/.config/raycast/scripts/` (kept out of `~/.config/raycast/` itself,
  which Raycast uses for its own data). Add the folder once on a new machine
  via Raycast → Settings → Extensions → Script Commands → Add Script Directory.

## Structure

- `home/` — chezmoi-managed home directory
- `home/.chezmoidata/` — layered YAML config data
- `home/.chezmoiscripts/` — setup scripts (brew, packages, vim, neovim, vscode)
- `macos-scripts/` — macOS system defaults
- `scripts/` — helper scripts (ssh-keygen, iterm2 prefs export)
- `init.sh` — bootstrap entrypoint

## macOS defaults

```bash
macos-scripts/macos-defaults.sh --audit   # report drift, change nothing
macos-scripts/macos-defaults.sh           # apply all sections
macos-scripts/macos-defaults.sh --update  # also install macOS software updates
```

## Editors

- **VS Code** — editor-of-record: `home/dot_config/Code/User/` +
  `home/.chezmoidata/vscode.yml`
- **Vim** — legacy: `home/dot_vimrc`
- **Neovim** — parallel LazyVim setup in `home/dot_config/nvim/`, mirroring
  the VS Code workflow. Open `nvim` once after applying to finish Mason and
  tree-sitter installs; run `:LazyHealth` if something feels off.
  Keybindings: [docs/nvim-cheat-sheet.md](docs/nvim-cheat-sheet.md)

## Testing

CI runs `./test.sh` (shellcheck, chezmoi template render, dry-run apply).
It also runs locally; requires `shellcheck` and `chezmoi` on `PATH`.
