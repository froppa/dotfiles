# Dotfiles production-readiness audit

Date: 2026-08-01  
Branch: `agent/ghostty-tmux-raycast`  
Audited commit: `677c5ae`

## Executive summary

Verdict: **not ready for an unattended fresh-machine apply yet**.

The repository passes its current CI and an isolated, script-free Chezmoi apply
is idempotent. The encrypted SSH key is managed correctly, and a redacted
Gitleaks scan of all 37 reachable commits found no confirmed plaintext secret.
However, VS Code is split across two divergent target trees, the live machine is
not aligned with the source state, and several bootstrap and security controls
need tightening before the setup is safely repeatable.

## Blocking findings

### PR-01 — VS Code has two divergent sources and the macOS settings filename is wrong

Severity: high (correctness and portability)

- Linux/XDG files live under `home/dot_config/Code/User/`.
- macOS files live under
  `home/private_Library/private_Application Support/private_Code/User/`.
- `home/.chezmoiignore:1-11` contains no operating-system routing, so both trees
  are managed on every platform.
- The keybindings are identical, but the launch files differ.
- The macOS source manages `settings.jsonc`; VS Code actually reads
  `~/Library/Application Support/Code/User/settings.json` on macOS.
- The real macOS `settings.json` exists and is currently unmanaged.
- `README.md:107-108` incorrectly calls only `home/dot_config/Code/User/` the
  editor of record.

Impact: a fresh Mac does not receive the intended VS Code settings, while edits
can silently diverge between the macOS and Linux copies.

Required remediation: keep one canonical VS Code template under
`.chezmoitemplates/`, render it to the platform-specific `settings.json` paths,
and conditionally ignore the other platform's path using `.chezmoi.os`.

### PR-02 — The live machine is not aligned with the source state

Severity: high (data-loss and rollout risk)

`chezmoi status --exclude scripts,encrypted` currently reports:

- 104 modified targets
- 27 targets that Chezmoi would delete
- 2 targets that Chezmoi would add

Some of this is representation drift: live Oh My Zsh and TPM directories are
Git checkouts while `home/.chezmoiexternal.toml:1-45` declares exact archives.
But the set also contains real user files including aliases, exports, functions,
Neovim, Starship, Hammerspoon, Raycast Quick Capture, and both VS Code settings
trees.

Impact: recommending `chezmoi apply` now could overwrite intentional local
changes and replace plugin checkouts without a reviewed reconciliation.

Required remediation: classify every non-external status entry, re-add only
intentional target changes, then test a clean diff. Recreate external-managed
directories in an isolated destination rather than broad-applying over the live
checkouts during reconciliation.

### PR-03 — SSH defaults are too broad and generated keys have no passphrase

Severity: high (credential security and host compatibility)

- `scripts/ssh-keygen.sh:21` passes `-N ""`, deliberately creating an
  unprotected private key.
- `home/private_dot_ssh/config:2-7` applies one `IdentityFile` and
  `IdentitiesOnly yes` to every SSH host.

Impact: theft of the decrypted target key gives immediate key access, and the
global `IdentitiesOnly` policy can prevent work hosts or other accounts from
using separate agent identities.

Required remediation: let `ssh-keygen` prompt for a passphrase; keep
`AddKeysToAgent` and `UseKeychain` under `Host *`, but scope `IdentityFile` and
`IdentitiesOnly` to explicit hosts such as `github.com`. Add an optional
`~/.ssh/config.d/*.conf` include for machine-specific identities.

### PR-04 — tmux status path crosses a shell-command boundary

Severity: high (local command execution)

`home/dot_config/tmux/tmux.conf:55` expands `#{pane_current_path}` inside a
double-quoted `#()` shell command. A repository or directory name containing
shell substitutions or a quote can alter the command that tmux executes while
rendering its status line.

Impact: entering an attacker-controlled directory can trigger local shell
execution through the continuously refreshed status command.

Required remediation: pass only a safe pane identifier to the script and query
the pane path through tmux, or use a tmux-native format that does not interpolate
the path into shell source text.

## Important hardening findings

### PR-05 — A fresh machine does not install VS Code reliably

Severity: medium

VS Code is called the editor of record at `README.md:105-108`, but
`home/.chezmoidata/40-packages.yml:65-89` does not install the
`visual-studio-code` cask. The extension script exits successfully when `code`
is missing (`home/.chezmoiscripts/run_onchange_30-install-vscode-extensions.sh.tmpl:4-7`),
so Chezmoi can record it as completed and never retry until the rendered script
changes.

Required remediation: install the cask before the extension script, or make the
script fail/retry when VS Code is expected but unavailable.

### PR-06 — Download and plugin supply chains are only partially pinned

Severity: medium

- CI installs Chezmoi through a live remote shell pipeline at
  `.github/workflows/ci.yml:41-45`.
- Homebrew is installed from `HEAD` at
  `home/.chezmoiscripts/run_once_10-install-homebrew.sh:3-6`.
- External archive URLs are tag/SHA-oriented but have no checksums
  (`home/.chezmoiexternal.toml:1-45`).
- TPM itself is pinned, but plugins declared at
  `home/dot_config/tmux/tmux.conf:58-63` resolve their default branches rather
  than immutable revisions.

Required remediation: pin CI actions and downloaded binaries to immutable
digests, add checksums to externals, and either vendor tmux plugins as pinned
Chezmoi externals or document them as intentionally rolling.

### PR-07 — CI does not exercise the primary platform or secret policy

Severity: medium

- `.github/workflows/ci.yml:15-19` runs only on Ubuntu although the repository is
  primarily a macOS bootstrap.
- `test.sh` checks shell syntax, template data, and a dry-run apply, but it does
  not validate macOS paths, JSON/JSONC configuration, external checksums, or
  secrets.
- A full-history redacted Gitleaks scan found six generic-key false positives,
  all in keybinding/workflow syntax, and no confirmed leak. There is no checked-in
  allowlist or CI scan to preserve that result.

Required remediation: add a macOS CI job, add configured Gitleaks scanning, and
test platform routing plus an isolated second apply with zero diff.

### PR-08 — GitHub repository governance is permissive

Severity: medium

The repository is public, `master` has no branch protection, all third-party
Actions are allowed, and full-SHA pinning is not required. Workflow token
permissions are correctly read-only (`.github/workflows/ci.yml:8-9`).

Required remediation: protect `master`, require the CI check, disallow force
pushes, restrict allowed Actions, and pin action references to full commit SHAs.

### PR-09 — Runtime and package intent is not reproducible

Severity: medium

- `home/dot_config/mise/config.toml:6-9` uses `latest` for Go, Ruby, pnpm, and
  Yarn.
- `home/dot_config/mise/config.toml:10` still globally installs Java despite the
  explicit decision that Java should not be global.
- `home/.chezmoiscripts/run_once_10-install-homebrew.sh:12-13` performs an
  unbounded `brew update` and `brew upgrade` during bootstrap.

Impact: two machines bootstrapped on different days do not converge on the same
toolchain, and Java has regressed into the global setup.

Required remediation: remove global Java, pin meaningful runtime channels or
versions, and separate explicit maintenance upgrades from first apply.

### PR-10 — iTerm2 migration residue and architecture assumptions remain

Severity: medium

- `home/.chezmoiscripts/run_once_after_50-configure-iterm2.sh:1-10` still
  configures iTerm2 even though Ghostty is now the terminal.
- `README.md:94` still describes the iTerm2 export helper.
- `home/dot_config/ghostty/config:51` hard-codes Apple Silicon Homebrew's
  `/opt/homebrew/bin/tmux`, so the advertised Linux/Intel portability does not
  hold.

Required remediation: remove the obsolete iTerm2 source/script after preserving
any intentionally archived preferences, and launch tmux through a portable,
verified command path.

## Controls that passed

- Current local `./test.sh`: pass.
- Current PR checks: pass.
- Isolated Chezmoi apply excluding scripts/encrypted entries: pass.
- Second isolated diff after apply: zero lines (idempotent).
- `chezmoi doctor`: all functional checks pass except the latest-version query,
  which was blocked by GitHub rate limiting.
- Current plist structure: valid.
- Current shell scripts: ShellCheck passes.
- Repository history scan: no confirmed plaintext secret; six classified false
  positives.
- SSH source uses age encryption and the target is marked private.
- Workflow token permissions are read-only.

## Recommended remediation order

1. Fix PR-04 (tmux command boundary) and PR-03 (SSH generation/config scope).
2. Consolidate and platform-route VS Code (PR-01), then add its package (PR-05).
3. Reconcile live Chezmoi drift without a broad apply (PR-02).
4. Remove Java and stale iTerm2 behavior; fix Ghostty portability (PR-09/10).
5. Add macOS, idempotence, secret, and supply-chain gates (PR-06/07/08).
6. Run a disposable fresh-macOS bootstrap and verify Ghostty, tmux restoration,
   Raycast import, SSH, VS Code/Zed, and a second no-op apply.

Production-ready means the final disposable bootstrap passes, the live
`chezmoi diff` is intentionally empty, and protected CI enforces the same result.

## Reference basis

- [VS Code user settings locations](https://code.visualstudio.com/docs/configure/settings)
- [Chezmoi machine-to-machine path routing](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/)
- [GitHub Actions full-SHA policy](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository)
