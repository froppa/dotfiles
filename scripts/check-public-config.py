"""Keep tracked workstation configuration free of machine and credential data."""

import ipaddress
import json
from pathlib import Path
import re
import subprocess


ROOT = Path(__file__).resolve().parents[1]
CONFIG_APPS = {
    "Code", "ghostty", "git", "mise", "nvim", "starship.toml",
    "systemd", "tmux", "zed", "zsh",
}
MANAGED_COMMANDS = {"clip-serve", "follow-main.sh", "wl-paste"}
PATTERNS = {
    "machine home path": r"/(?:Users|home)/(?!linuxbrew(?:/|\b))[A-Za-z0-9_.-]+/",
    "password-manager item": r"\bop[:][/]{2}[^\s\"']+",
    "private key": r"-----BEGIN (?:[A-Z0-9]+ )?PRIVATE KEY-----",
    "credential value": r"\b(?:gh[pousr]_[A-Za-z0-9]{20,}|sk-(?:proj-)?[A-Za-z0-9_-]{20,}|AKIA[A-Z0-9]{16})\b",
}


def findings(path, text):
    """Return categories only, so a CI failure never prints confidential values."""
    issues = []
    for category, pattern in PATTERNS.items():
        if re.search(pattern, text):
            issues.append(category)
    for value in re.findall(r"\b[A-Za-z0-9_.-]+@(?:[A-Za-z0-9_-]+\.)+[A-Za-z0-9_-]+", text):
        if value not in {"git@github.com", "ci@example.invalid"}:
            issues.append("literal user or SSH identity")
            break
    for value in re.findall(r"(?<![\w.])(?:\d{1,3}\.){3}\d{1,3}(?![\w.])", text):
        try:
            address = ipaddress.ip_address(value)
        except ValueError:
            continue
        if address != ipaddress.ip_address("127.0.0.1") and not address.is_unspecified:
            issues.append("literal network address")
            break
    parts = Path(path).parts
    if parts[:2] == ("home", "dot_config") and parts[2] not in CONFIG_APPS:
        issues.append("unreviewed managed application")
    if parts[:3] == ("home", "dot_local", "bin"):
        command = parts[3].removeprefix("executable_")
        if command not in MANAGED_COMMANDS:
            issues.append("unreviewed managed command")
    if path == "home/dot_config/zed/private_settings.json":
        settings = json.loads(text)
        if "language_models" in settings or any(
            "model" in key for key in settings.get("agent", {})
        ):
            issues.append("managed model or endpoint selection")
    return issues


def main():
    tracked = subprocess.check_output(
        ["git", "ls-files", "-z"], cwd=ROOT
    ).decode().split("\0")
    failed = False
    checked = 0
    for name in filter(None, tracked):
        path = ROOT / name
        # A deletion in a working tree is already absent from the proposed snapshot.
        if not path.is_file():
            continue
        checked += 1
        for issue in findings(name, path.read_text()):
            print(f"{name}: {issue}")
            failed = True
    if failed:
        raise SystemExit(1)
    print(f"Public configuration boundaries passed for {checked} tracked files.")


if __name__ == "__main__":
    main()
