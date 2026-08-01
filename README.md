# Dotfiles

[![CI](https://github.com/froppa/dotfiles/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/froppa/dotfiles/actions/workflows/ci.yml)
[![Chezmoi](https://img.shields.io/badge/managed%20with-chezmoi-6e4c1e)](https://www.chezmoi.io/)
![Platform](https://img.shields.io/badge/platform-macOS%20%2B%20Linux-lightgrey)

Personal development environment managed with Chezmoi. macOS is the primary
platform; the shell, Git, editor, and XDG configuration also cover Linux where
the underlying tools are available.

## What it configures

- Ghostty launching into a persistent tmux session
- Raycast Hyper shortcuts for tmux windows and panes
- Zsh, Starship, Git, GPG, SSH, and common CLI tools
- Zed, VS Code, Vim, Neovim, and Hammerspoon
- Homebrew packages with personal and work profiles
- Raycast settings, Script Commands, and Quick Capture
- macOS defaults through an explicit, separate command

Chezmoi source state lives in [`home/`](home/). External shell and tmux plugins
are declared in [`home/.chezmoiexternal.toml`](home/.chezmoiexternal.toml).

## Bootstrap

### Using the checked-in SSH key

The encrypted SSH payload is tied to the age recipient in
[`home/.chezmoi.toml.tmpl`](home/.chezmoi.toml.tmpl). A matching identity must be
available at `~/.config/sops/age/keys.txt` before the encrypted entry can be
applied.

```bash
install -d -m 700 ~/.config/sops/age
# Place the matching keys.txt at ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

PERSONAL=true sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply froppa
```

Use `WORK=true` instead of `PERSONAL=true` for the work package profile.

For a repository checkout plus the complete bootstrap flow:

```bash
git clone https://github.com/froppa/dotfiles.git ~/.local/share/chezmoi
cd ~/.local/share/chezmoi
./init.sh --macos
```

`./init.sh --help` lists the Git identity and signing-key options. `--macos`
applies the settings in `macos-scripts/` after Chezmoi completes.

### Applying without the encrypted SSH key

The public configuration can be applied without an age identity:

```bash
PERSONAL=true sh -c "$(curl -fsLS get.chezmoi.io)" -- \
  init --apply --exclude encrypted froppa
```

This installs the managed configuration while leaving encrypted entries out of
the apply.

### Using a different age identity

The checked-in ciphertext is specific to this repository owner. A fork can
continue excluding encrypted entries, or replace the age recipient and encrypt
its own SSH key.

From a cloned fork:

```bash
cd ~/.local/share/chezmoi

chezmoi init --source "$PWD" --apply --exclude encrypted

install -d -m 700 ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt
```

Use the printed recipient for `[age].recipient` in
`home/.chezmoi.toml.tmpl`, then refresh the local Chezmoi configuration and
replace the encrypted SSH source:

```bash
chezmoi init --source "$PWD"
./scripts/import-ssh-key.sh ~/.ssh/id_ed25519
chezmoi diff
```

`import-ssh-key.sh` also adds the matching public key when it exists. The
resulting encrypted source can then be reviewed and committed in the fork.

## SSH behavior

SSH uses [`home/private_dot_ssh/config`](home/private_dot_ssh/config):

- `~/.ssh/id_ed25519` is the configured identity
- macOS Keychain integration is enabled when supported
- the agent receives the key on first use through `AddKeysToAgent`
- shell startup does not run `ssh-add`

To encrypt an existing key into the Chezmoi source:

```bash
./scripts/import-ssh-key.sh ~/.ssh/id_ed25519
```

To create a new Ed25519 key first:

```bash
./scripts/ssh-keygen.sh
./scripts/import-ssh-key.sh ~/.ssh/id_ed25519
```

## Terminal workflow

Ghostty starts or attaches to the tmux session named `main`. Raycast owns Caps
Lock and emits `Ctrl+Option+Command`; Ghostty translates those chords into tmux
prefix commands while Right Option remains available for Danish symbols.

| Shortcut | Action |
| --- | --- |
| `Caps+C` | New tmux window |
| `Caps+I` | Side-by-side pane |
| `Caps+-` | Stacked pane |
| `Caps+Arrow` | Move between panes |
| `Caps+0…9` | Select tmux window |
| `Caps+Z` | Toggle pane zoom |
| `Caps+R` | Reload tmux configuration |
| `Caps+X` / `Caps+W` | Kill pane after confirmation |

tmux configuration and status scripts live under
[`home/dot_config/tmux/`](home/dot_config/tmux/). TPM is pinned as a Chezmoi
external; declared plugins are installed by an onchange script. Continuum and
Resurrect retain session restoration.

## Applications and settings

### Raycast

The Raycast export is managed at
`~/.config/raycast/raycast.rayconfig` and imported through Raycast's
**Import Settings & Data** action. Its export passphrase is separate from
Chezmoi and age.

Script Commands are applied to `~/.config/raycast/scripts/`. Add that directory
once in Raycast under **Settings → Extensions → Script Commands**.

### Editors

- Zed settings and keybindings: `home/dot_config/zed/`
- VS Code XDG settings: `home/dot_config/Code/User/`
- VS Code extension list: `home/.chezmoidata/vscode.yml`
- Neovim: `home/dot_config/nvim/`
- Vim: `home/dot_vimrc`

The VS Code extension script runs when the `code` CLI is available. Neovim uses
Lazy and may finish language tooling setup on its first interactive launch.

### Packages and runtimes

Homebrew package data lives in
[`home/.chezmoidata/40-packages.yml`](home/.chezmoidata/40-packages.yml).
Changes rerender the Brew bundle and rerun its Chezmoi onchange script.

Global language runtimes are defined in
[`home/dot_config/mise/config.toml`](home/dot_config/mise/config.toml).

## Daily workflow

```bash
chezmoi diff                     # inspect target/source differences
chezmoi apply -v                 # apply the current source
chezmoi update -v                # pull and apply
chezmoi edit --apply ~/.zshrc    # edit a managed target
chezmoi re-add ~/.zshrc          # capture an intentional target change
chezmoi cd                       # open the source repository
```

Machine-specific values belong in the unmanaged `*.local` files sourced by the
shell and Git configuration, including `.zshrc.local`, `.exports.local`,
`.aliases.local`, `.functions.local`, and `.gitconfig.local`.

## macOS defaults

```bash
macos-scripts/macos-defaults.sh --audit
macos-scripts/macos-defaults.sh
macos-scripts/macos-defaults.sh --update
```

`--audit` reports differences without changing them. The default command applies
the configured sections; `--update` also includes macOS software updates.

## Repository layout

| Path | Purpose |
| --- | --- |
| `home/` | Chezmoi source state |
| `home/.chezmoidata/` | Package, feature, and editor data |
| `home/.chezmoiscripts/` | Ordered and change-triggered setup scripts |
| `macos-scripts/` | macOS defaults and Dock/Finder/keyboard setup |
| `scripts/` | Import, export, and key-generation helpers |
| `docs/` | Reference notes |
| `init.sh` | Local repository bootstrap |
| `test.sh` | Local and CI validation |

## Validation

```bash
./test.sh
```

The test suite runs ShellCheck, verifies executable scripts, renders both
personal and work Chezmoi configurations, and performs a dry-run apply without
encrypted entries. GitHub Actions runs the same suite for pushes and pull
requests.
