# Dotfiles

[![CI](https://github.com/froppa/dotfiles/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/froppa/dotfiles/actions/workflows/ci.yml)
[![Chezmoi](https://img.shields.io/badge/managed%20with-chezmoi-6e4c1e)](https://www.chezmoi.io/)
![Platform](https://img.shields.io/badge/platform-macOS%20%2B%20Linux-lightgrey)

Personal macOS development environment managed with Chezmoi and Homebrew.
Shell, Git, editor, and XDG configuration also work on Linux where supported.

## Overview

| Area | Configuration |
| --- | --- |
| Terminal | Ghostty opens the persistent tmux session `main` |
| Shell | Zsh, Oh My Zsh, Starship, fzf, mise, and direnv |
| Editors | Zed, VS Code, Vim, and Neovim |
| Shortcuts | Raycast Caps Lock Hyper translated by Ghostty into tmux commands |
| Packages | Homebrew bundle with personal and work profiles |
| Secrets | Owner SSH key encrypted with age; Raycast export encrypted by Raycast |
| macOS | Dock, Finder, keyboard, Safari, and general defaults |

## Install

```bash
git clone https://github.com/froppa/dotfiles.git ~/.local/share/chezmoi
cd ~/.local/share/chezmoi
./init.sh --macos
```

Use `WORK=true ./init.sh --macos` for the work package profile. Run
`./init.sh --help` for Git identity and signing-key options. Omit `--macos` to
apply the dotfiles without changing macOS defaults.

### SSH and age

The repository contains the owner's age-encrypted `~/.ssh/id_ed25519`. It can
only be applied with the matching identity at
`~/.config/sops/age/keys.txt`.

This encrypted entry is owner-specific. Apply everything else with:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- \
  init --apply --exclude encrypted froppa
```

A fork can replace the recipient in `home/.chezmoi.toml.tmpl` and encrypt its
own key with `scripts/import-ssh-key.sh`.

SSH behavior is config-driven: `AddKeysToAgent` and macOS Keychain integration
load the key on first use. Shell startup does not call `ssh-add`.

## Manual steps

| Component | Once per machine |
| --- | --- |
| Raycast | Import `~/.config/raycast/raycast.rayconfig` using Raycast's import action |
| Raycast scripts | Add `~/.config/raycast/scripts/` as a Script Command directory |
| Neovim | Open once to finish Lazy, Mason, and tree-sitter setup |

The Raycast export passphrase is separate from age. tmux plugins install through
TPM; Continuum and Resurrect handle session restoration.

## Terminal shortcuts

Raycast owns Caps Lock and emits `Ctrl+Option+Command`. Ghostty converts the
following chords to tmux commands. Right Option remains available for Danish
symbols.

| Shortcut | Action |
| --- | --- |
| `Caps+C` | New window |
| `Caps+I` | Side-by-side pane |
| `Caps+-` | Stacked pane |
| `Caps+Arrow` | Move between panes |
| `Caps+0…9` | Select window |
| `Caps+Z` | Toggle pane zoom |
| `Caps+R` | Reload tmux |
| `Caps+X` / `Caps+W` | Kill pane after confirmation |

## Daily use

```bash
chezmoi diff                     # inspect changes
chezmoi apply -v                 # apply source state
chezmoi update -v                # pull and apply
chezmoi edit --apply ~/.zshrc    # edit through Chezmoi
chezmoi re-add ~/.zshrc          # capture a target change
chezmoi cd                       # open the source repository
```

Machine-specific overrides use unmanaged `*.local` files such as
`.zshrc.local`, `.exports.local`, `.aliases.local`, `.functions.local`, and
`.gitconfig.local`.

## Where things live

| Path | Purpose |
| --- | --- |
| `home/dot_config/ghostty/` | Ghostty and Hyper mappings |
| `home/dot_config/tmux/` | tmux, status scripts, and plugins |
| `home/dot_config/raycast/` | Raycast export and Script Commands |
| `home/dot_config/zed/` | Zed settings and keybindings |
| `home/dot_config/Code/User/` | VS Code XDG settings |
| `home/dot_config/nvim/` | Neovim configuration |
| `home/.chezmoidata/` | Packages, profiles, and VS Code extensions |
| `home/.chezmoiscripts/` | Ordered and change-triggered setup |
| `home/.chezmoiexternal.toml` | Pinned shell and TPM sources |
| `macos-scripts/` | Auditable macOS defaults |
| `scripts/` | SSH and preference helpers |

## macOS defaults

```bash
macos-scripts/macos-defaults.sh --audit   # show differences
macos-scripts/macos-defaults.sh           # apply defaults
macos-scripts/macos-defaults.sh --update  # apply and update macOS
```

## Validate

```bash
./test.sh
```

The same ShellCheck, template, profile, and Chezmoi dry-run checks run in CI.
Neovim reference: [docs/nvim-cheat-sheet.md](docs/nvim-cheat-sheet.md).
