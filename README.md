# Dotfiles

[![CI](https://github.com/froppa/dotfiles/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/froppa/dotfiles/actions/workflows/ci.yml)
[![Chezmoi](https://img.shields.io/badge/managed%20with-chezmoi-6e4c1e)](https://www.chezmoi.io/)
![Platform](https://img.shields.io/badge/platform-macOS%20%2B%20Linux-lightgrey)

Personal macOS development environment managed with Chezmoi and Homebrew.
Shell, Git, editor, and XDG configuration also work on Linux where supported.

## Overview

| Area | Configuration |
| --- | --- |
| Terminal | Ghostty natively for tabs, splits, and scrollback; tmux only for sessions that must outlive the window (`tm` locally, `ssht <host>` remotely) |
| Shell | Zsh, Oh My Zsh, Starship, fzf, mise, and direnv |
| Editors | Zed, VS Code, Vim, and Neovim |
| Shortcuts | Raycast Caps Lock Hyper chords, the same keys in Ghostty and under `Ctrl-a` in tmux |
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
| SwiftBar | Launch once and allow it to run; the plugin directory is preset to `~/.config/swiftbar` |

Raycast exports are intentionally not managed because they can contain private
local data and did not reliably restore settings. To add a Ghostty launcher,
open Raycast's Applications extension, add a Command for Ghostty, and assign the
hotkey there. tmux plugins install through TPM; Continuum and Resurrect handle
session restoration.

## Terminal shortcuts

Raycast owns Caps Lock and emits `Ctrl+Option+Command`. Ghostty maps the
chords below to its own tabs and splits; inside a tmux session the same keys
work after the `Ctrl-a` prefix. Right Option remains available for Danish
symbols.

| Shortcut | Ghostty | tmux (`Ctrl-a` + key) |
| --- | --- | --- |
| `Command+K` | Clear the screen of the active application | same |
| `Shift+Enter` | Newline in Claude Code and shell prompts | same |
| `Caps+C` | New tab | New window |
| `Caps+I` / `Caps+-` | Split right / down | Same |
| `Caps+Arrow` | Move between splits | Move between panes |
| `Caps+Shift+Arrow` | Resize split | Resize pane |
| `Caps+=` | Equalize splits | |
| `Caps+Z` | Zoom split | Zoom pane |
| `Caps+X` / `Caps+W` | Close split or tab | Kill pane after confirmation |
| `Caps+1…9` / `Caps+0` | Go to tab / last tab | Window 0…9 |
| `Caps+N` / `Caps+P` | Next / previous tab | Same |
| `Caps+F` | Tab overview | Window picker |
| `Caps+R` | Reload Ghostty config | Reload tmux config |
| `Caps+,` `Caps+B` `Caps+J` `Caps+M` `Caps+U` `Caps+H` | | Rename, break, join, move, URL picker, cheat sheet |

`tm` attaches to (or creates) the persistent local tmux session `main`;
`ssht <host> [session]` does the same on a remote machine over ssh, tinting
Ghostty's background in the host's colour and titling the tab after it until
the connection ends. Outside tmux, Claude Code rings the terminal bell when it
needs attention and Ghostty marks the tab. Starship's right prompt shows the
ssh host, running agents (with how many are working or waiting for you), and
remaining limits from the same caches the tmux status bar uses, refreshed in
the background; it is cleared once a command runs so history stays clean. The
same facts sit in the macOS menu bar through SwiftBar: the title shows the
Claude count, working and waiting sessions, and the 7-day figure; the menu
lists each session with its directory and state.

### tmux status bar

Inside a tmux session, row one is the context badge and the window tabs: `⌂ local`, or `⇅ host` in a
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
| `home/dot_config/swiftbar/` | Menu bar item with agent sessions and limits |
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
