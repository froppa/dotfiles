# Dotfiles

[![CI](https://github.com/froppa/dotfiles/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/froppa/dotfiles/actions/workflows/ci.yml)
[![Chezmoi](https://img.shields.io/badge/managed%20with-chezmoi-6e4c1e)](https://www.chezmoi.io/)
![Platform](https://img.shields.io/badge/platform-macOS%20%2B%20Linux-lightgrey)

Personal macOS development environment managed with Chezmoi and Homebrew.
Shell, Git, editor, and XDG configuration also work on Linux where supported.

## Overview

| Area | Configuration |
| --- | --- |
| Terminal | Ghostty opens the persistent tmux session `main`; the tmux status bar shows where the active pane runs, running agents, and Claude and Codex limits |
| Shell | Zsh, Oh My Zsh, Starship, fzf, mise, and direnv |
| Editors | Zed, VS Code, Vim, and Neovim |
| Shortcuts | Raycast Caps Lock Hyper translated by Ghostty into tmux commands |
| Packages | Homebrew bundle with personal and work profiles |
| SSH | Portable client config; keys stay local to each machine |
| macOS | Dock, Finder, keyboard, Safari, and general defaults |

## Install

On a fresh macOS or Linux machine, one command installs chezmoi into
`~/.local/bin`, clones this repository, and applies it:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/froppa/dotfiles/master/bootstrap.sh)"
```

Run it through `sh -c` rather than piping into `sh` so the Git identity prompts
can read the terminal; `GIT_NAME` and `GIT_EMAIL` in the environment skip them
and `WORK=true` selects the work profile. On macOS it then offers the defaults
script. With the repository already cloned, the equivalent is:

```bash
git clone https://github.com/froppa/dotfiles.git ~/.local/share/chezmoi
cd ~/.local/share/chezmoi
./init.sh --macos
```

Use `WORK=true ./init.sh --macos` for the work package profile. An existing
`~/.gitconfig` is left unchanged and any detected global identity is reused. If
the file does not exist, bootstrap prompts for a missing Git name or email
before creating the default config. Put machine-specific overrides or signing
settings in `~/.gitconfig.local`. On new machines, the root config includes
repository defaults from the managed `~/.config/git/dotfiles.gitconfig`. Omit
`--macos` to apply the dotfiles without changing macOS defaults.

### SSH

SSH keys are never managed by this repository. Generate a new key on each
machine when needed:

```bash
./scripts/ssh-keygen.sh
```

SSH behavior is config-driven: `AddKeysToAgent` and macOS Keychain integration
load the key on first use. Shell startup does not call `ssh-add`.

## Manual steps

| Component | Once per machine |
| --- | --- |
| Raycast | Configure Caps Lock as Hyper (`Control+Option+Command`, no Shift) |
| Raycast scripts | Add `~/.config/raycast/scripts/` as a Script Command directory |
| Neovim | Open once to finish Lazy, Mason, and tree-sitter setup |

Raycast exports are intentionally not managed because they can contain private
local data and did not reliably restore settings. To add a Ghostty launcher,
open Raycast's Applications extension, add a Command for Ghostty, and assign the
hotkey there. tmux plugins install through TPM; Continuum and Resurrect handle
session restoration.

## Terminal shortcuts

Raycast owns Caps Lock and emits `Ctrl+Option+Command`. Ghostty converts the
following chords to tmux commands. Right Option remains available for Danish
symbols.

| Shortcut | Action |
| --- | --- |
| `Command+K` | Clear the active application screen through tmux |
| `Shift+Enter` | Insert a newline in Claude Code and shell prompts |
| `Caps+C` | New window |
| `Caps+I` | Side-by-side pane |
| `Caps+-` | Stacked pane |
| `Caps+Arrow` | Move between panes |
| `Caps+0…9` | Select window |
| `Caps+Z` | Toggle pane zoom |
| `Caps+R` | Reload tmux |
| `Caps+X` / `Caps+W` | Kill pane after confirmation |
| `Caps+,` | Rename window |
| `Caps+N` / `Caps+P` / `Caps+Tab` | Next, previous, last window |
| `Caps+F` | Pick a window from a list |
| `Caps+B` | Break the pane out into its own window |
| `Caps+J` / `Caps+M` | Join a pane from, or move this pane to, another window |
| `Caps+Shift+Arrow` | Resize pane |
| `Caps+U` | Pick a URL from the pane history and open it |
| `Caps+H` | tmux cheat sheet; row two of the status bar carries the hint |

Every chord is the tmux prefix `Ctrl-a` plus the same key, so it also works
from a plain keyboard. Windows are named after their directory or ssh host;
rename one and the name sticks. Mouse drag, double-click, and triple-click copy
to the clipboard without leaving copy mode; `Cmd+V` pastes; `Cmd+click` opens
a link; hold Shift to let Ghostty select text itself.

### tmux status bar

Row one is the context badge and the window tabs: `⌂ local`, or `⇅ host` in a
colour derived from the host name when the active pane runs `ssh` (or when tmux
itself runs on a machine reached over ssh). The bar tint and the active pane
border follow the same colour. A tab whose pane runs `claude` or `codex`
carries a `✦` or `◆` icon in that agent's colour. Claude Code hooks in
`~/.claude/settings.json` call `agent-state.sh`, so the `✦` is orange while the
session works, yellow `✦?` when it waits for a permission or answer, and grey
once its turn is finished; a split window shows `|`
(side by side), `-` (stacked) or `|-`, and `Z` marks a zoomed one. Row two shows running Claude (`✦`) and Codex (`◆`)
CLI sessions, the remaining 7-day limit for
Claude Code and Codex read from their OAuth usage endpoints with the tokens the
CLIs already store (cached 5 min), the git branch, and RAM. Claude Code's own
status line keeps only model, effort, and context left.

Claude Code keeps `~/.claude/settings.json` itself, so the tab-state hooks are
installed once per machine with `scripts/claude-tmux-hooks.sh`, which merges
them idempotently. Two unmanaged files under `~/.config/tmux/` keep host
details out of this repository:

| File | Content |
| --- | --- |
| `hosts.local` | `<host> <accent> <tint>` hex colours overriding the derived ones |
| `agent-hosts.local` | ssh aliases, one per line, whose agent counts are fetched over ssh every minute |

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

Depot is installed separately with Cargo from `struktly/tools`. The managed
`~/.local/bin/depot` link points to `~/.cargo/bin/depot`, replacing the legacy
Verk entry point. Zsh loads completion from the installed Depot version after
completion initialization; no generated completion file needs updating.

## Where things live

| Path | Purpose |
| --- | --- |
| `home/dot_config/ghostty/` | Ghostty and Hyper mappings |
| `home/dot_config/tmux/` | tmux, status scripts, and plugins |
| `home/dot_config/raycast/` | Raycast Script Commands |
| `home/dot_config/zed/` | Zed settings and keybindings |
| `home/dot_config/Code/User/` | VS Code XDG settings |
| `home/dot_config/nvim/` | Neovim configuration |
| `home/.chezmoidata/` | Packages, profiles, and VS Code extensions |
| `home/.chezmoiscripts/` | Ordered and change-triggered setup |
| `home/.chezmoiexternal.toml` | Pinned shell and TPM sources |
| `macos-scripts/` | Auditable macOS defaults |
| `scripts/` | Local SSH key generation, Claude Code hook install, and preference helpers |

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
