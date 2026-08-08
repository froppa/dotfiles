# Bugs

## 2026-08-08 — terminal and machine-adoption issues

- In Ghostty's automatically started `main` tmux session, Command-K does not behave smoothly. The tracked Ghostty configuration starts tmux directly, but there is no explicit Command-K mapping in the Ghostty or tmux configuration.
- In `claude` CLI inside this terminal setup, Shift-Enter pastes instead of inserting a new line. No Shift-Enter mapping is currently tracked in the Ghostty or tmux configuration.
- Adopting the setup on a work PC was confusing: bootstrap set unexpected Git settings and did not reuse the machine's existing Git setup. The current bootstrap prompts for and stores Git identity/signing values, then installs the repository's full Git config with `~/.gitconfig.local` as a trailing include.
- Importing the tracked Raycast export on the work PC exposed clipboard content from the personal machine. The expected Raycast settings did not come across, and setup still required a manual import. The repository tracks a binary `raycast.rayconfig`, and the README documents Raycast import as a manual per-machine step. Do not inspect or reproduce the clipboard contents while investigating.
