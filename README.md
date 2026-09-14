# Dotfiles

[![CI](https://github.com/froppa/dotfiles/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/froppa/dotfiles/actions/workflows/ci.yml)
[![Chezmoi](https://img.shields.io/badge/managed%20with-chezmoi-6e4c1e)](https://www.chezmoi.io/)
![Platform](https://img.shields.io/badge/platform-macOS%20%2B%20Linux-lightgrey)

Personal development environment managed with Chezmoi: Homebrew on macOS,
native apt packages on Ubuntu 26.04. Shell, Git, editor, and XDG configuration
are shared across both systems.

## Overview

| Area | Configuration |
| --- | --- |
| Terminal | Ghostty natively for tabs, splits, and scrollback; tmux only for sessions that must outlive the window (`tm` locally, `ssht <host>` remotely) |
| Shell | Zsh, Oh My Zsh, Starship, fzf, mise, and direnv |
| Editors | Zed, VS Code, Vim, and Neovim |
| Shortcuts | Raycast Caps Lock Hyper chords, the same keys in Ghostty and under `Ctrl-a` in tmux |
| Packages | Homebrew profiles on macOS; common native apt packages on Ubuntu |
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

### Ubuntu 26.04

Install the bootstrap prerequisites and Chezmoi, then preview before applying:

```bash
sudo apt-get update
sudo apt-get install -y git curl ca-certificates
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
git clone https://github.com/froppa/dotfiles.git ~/.local/share/chezmoi
cd ~/.local/share/chezmoi
chezmoi init --source="$PWD" --promptString 'name=sdf'
chezmoi diff
chezmoi apply -v
```

If already cloned, use that checkout instead of cloning again. Ubuntu setup
installs missing packages with apt and never installs or updates Linuxbrew.
An existing Linuxbrew installation is left on disk, but managed Zsh startup
no longer adds it to PATH. Personal and work profiles currently share the same
Ubuntu package set. Raycast, Hammerspoon, and iTerm2 configuration is macOS-only.

The native set covers shell, editor, Git, and common build tools. It does not
add third-party repositories or install mise, Codex, Claude Code, Docker,
OpenTofu, AWS CLI, lazygit, Ghostty, GUI editors, or Nerd Fonts. These remain
separate bootstrap steps; Ubuntu's `yq` is also not assumed equivalent to the
Homebrew formula. Once mise is installed, `mise install` installs the declared
runtimes; copying its configuration alone does not install them. Some Neovim
plugins need those runtimes before their first launch.

After applying, choose Zsh as your login shell if desired:

```bash
chsh -s "$(command -v zsh)"
```

Log out and back in. `fd` and `bat` aliases handle Ubuntu's executable names,
and fzf uses an executable path that also works in its subprocesses. The Linux
`update` alias uses apt. Mac-specific Hyper shortcuts require separate desktop
key bindings on Ubuntu.

Authenticate GitHub, Codex, and Claude freshly on Ubuntu as your normal user.
Do not copy tokens, private keys, or provider credential stores from another
machine. SSH access and the SSH server belong to the machine's infrastructure
setup; these dotfiles manage only portable client configuration. A remote
tmux session continues when you disconnect, but not when the Ubuntu VM shuts
down.

### Ubuntu AI tools

After applying the native package configuration, install Claude Code and mise
through their signed apt repositories, and Codex through its official standalone
installer:

```bash
./scripts/bootstrap-ubuntu-ai.sh
codex login
claude auth login
gh auth login --web
```

This does not authenticate automatically or copy credentials from your Mac.
Codex is pinned to the validated CLI version in the script. Runtime installation
is separate; do not run source-building plugin installers until the required
Depot build wrapper is available on the machine.

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

Raycast owns Caps Lock and emits `Ctrl+Option+Command`. Ghostty maps the
chords below to its own tabs and splits; inside a tmux session the same keys
work after the `Ctrl-a` prefix. Right Option remains available for Danish
symbols. `Caps+T` is a global binding, so macOS only delivers it once Ghostty
is ticked under System Settings > Privacy & Security > Accessibility; every
other chord works without that.

Closing a split or tab confirms while a process is still running, and a command
that took more than five seconds and finished while you were in another window
marks its tab and posts a notification. Both need Ghostty 1.3 or newer.

| Shortcut | Ghostty | tmux (`Ctrl-a` + key) |
| --- | --- | --- |
| `Command+K` | Clear the screen and the scrollback | Clears Ghostty's scrollback, not the pane |
| `Command+F` | Search the scrollback | Copy mode, then `/` |
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
| `Caps+F` | Tab overview (Linux only) | Window picker |
| `Caps+R` | Reload Ghostty config | Reload tmux config |
| `Caps+T` | Scratch terminal over any app | `display-popup` |
| `Caps+,` | Rename the tab | Rename window |
| `Caps+Shift+,` / `Caps+Shift+.` | Move the tab left / right | Move window left / right |
| `Caps+H` | Command palette, which lists every binding | Cheat sheet |
| `Caps+B` `Caps+J` `Caps+M` `Caps+U` | | Break, join, move pane, URL picker |

`tm` attaches to (or creates) the persistent local tmux session `main`;
`ssht <host> [session]` does the same on a remote machine over ssh, tinting
Ghostty's background in the host's colour and titling the tab after it until
the connection ends. The hooks also record each session's state under
`~/.cache/agents/claude-<session id>`, which Verk reads to list a waiting
terminal session in Today and in its menu bar. Outside tmux, the same hooks
retitle the Ghostty tab with the session's state and directory (`⟳ repo` working, `? repo` waiting for you,
`· repo` idle), Claude Code rings the terminal bell when it needs attention,
and Ghostty marks the tab. Starship's right prompt shows the
ssh host, running agents (with how many are working or waiting for you), and
remaining limits from the same caches the tmux status bar uses, refreshed in
the background; it is cleared once a command runs so history stays clean.

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
