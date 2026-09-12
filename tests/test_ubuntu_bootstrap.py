"""Exercise platform routing without touching package managers or the real home."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]
CHEZMOI = shutil.which("chezmoi")
SHELLCHECK = shutil.which("shellcheck")
ZSH = shutil.which("zsh")


class PackageBootstrapTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles platform-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.bin = self.base / "bin"
        self.bin.mkdir()
        self.log = self.base / "commands"
        self.config = self.base / "config.toml"
        self.config.write_text("")
        self.env = dict(os.environ, HOME=str(self.base), PATH=f"{self.bin}:/usr/bin:/bin",
                        TEST_LOG=str(self.log), BREWFILE=str(self.base / "Brewfile"))
        self.stub("sudo", 'printf "sudo %s\\n" "$*" >> "$TEST_LOG"\nexec "$@"\n')
        self.stub("apt-get", 'printf "apt-get %s\\n" "$*" >> "$TEST_LOG"\n'
                  'if [ "$1" = update ] && [ "${FAIL_UPDATE:-0}" = 1 ]; then exit 9; fi\n')
        self.stub("dpkg-query", 'if [ "${ALL_INSTALLED:-0}" = 1 ] || [ "$3" != fd-find ]; then\n'
                  '  printf "install ok installed"\nelse exit 1; fi\n')
        self.stub("brew", 'printf "brew %s\\n" "$*" >> "$TEST_LOG"\n'
                  'if [ "$1" = bundle ]; then cat > "$BREWFILE"; fi\n')
        self.stub("uname", 'printf "%s\\n" "${TEST_KERNEL:-Linux}"\n')
        self.stub("curl", 'echo "unexpected curl" >> "$TEST_LOG"; exit 77\n')

    def stub(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/sh\nset -eu\n" + body)
        path.chmod(0o755)

    def render(self, name, system="linux", distro="ubuntu", work=False):
        data = {"chezmoi": {"os": system, "osRelease": {"id": distro}},
                "personal": not work, "work": work}
        return subprocess.check_output([
            CHEZMOI, "--source", str(ROOT), "--config", str(self.config),
            "--override-data", json.dumps(data), "execute-template", "--file",
            str(ROOT / name)], text=True)

    def execute(self, script):
        return subprocess.run(["/bin/bash"], input=script, text=True, env=self.env,
                              capture_output=True)

    def commands(self):
        return self.log.read_text() if self.log.exists() else ""

    def test_ubuntu_installs_only_missing_native_packages(self):
        for work in (False, True):
            with self.subTest(work=work):
                self.log.unlink(missing_ok=True)
                result = self.execute(self.render(
                    "home/.chezmoiscripts/run_onchange_20-install-pkgs.sh.tmpl", work=work))
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(self.commands().splitlines(), [
                    "sudo apt-get update", "apt-get update",
                    "sudo apt-get install -y --no-install-recommends fd-find",
                    "apt-get install -y --no-install-recommends fd-find"])

    def test_installed_ubuntu_packages_do_not_call_sudo_or_brew(self):
        self.env["ALL_INSTALLED"] = "1"
        result = self.execute(self.render(
            "home/.chezmoiscripts/run_onchange_20-install-pkgs.sh.tmpl"))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.commands(), "")

    def test_apt_update_failure_stops_install(self):
        self.env["FAIL_UPDATE"] = "1"
        result = self.execute(self.render(
            "home/.chezmoiscripts/run_onchange_20-install-pkgs.sh.tmpl"))
        self.assertEqual(result.returncode, 9)
        self.assertNotIn("apt-get install", self.commands())

    def test_linux_never_bootstraps_homebrew(self):
        result = self.execute((ROOT / "home/.chezmoiscripts/run_once_10-install-homebrew.sh").read_text())
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.commands(), "")

    def test_darwin_preserves_brew_profiles(self):
        for work in (False, True):
            with self.subTest(work=work):
                self.log.unlink(missing_ok=True)
                result = self.execute(self.render(
                    "home/.chezmoiscripts/run_onchange_20-install-pkgs.sh.tmpl", system="darwin", work=work))
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(self.commands().splitlines(), ["brew bundle --file=/dev/stdin", "brew cleanup"])
                brewfile = (self.base / "Brewfile").read_text()
                self.assertIn('brew "xcode-build-server"', brewfile)
                self.assertIn('cask "raycast"', brewfile)
                self.assertIn('brew "awscli"' if work else 'brew "opentofu"', brewfile)
                self.assertNotIn('brew "opentofu"' if work else 'brew "awscli"', brewfile)

    def test_unsupported_linux_fails_without_package_mutations(self):
        result = self.execute(self.render(
            "home/.chezmoiscripts/run_onchange_20-install-pkgs.sh.tmpl", distro="fedora"))
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.commands(), "")

    def test_ubuntu_shell_aliases_and_fzf_subprocess(self):
        self.stub("fdfind", 'printf "fdfind %s\\n" "$*" >> "$TEST_LOG"\n')
        self.stub("batcat", 'printf "batcat %s\\n" "$*" >> "$TEST_LOG"\n')
        for name in ("fzf", "gpgconf", "mise", "direnv", "starship"):
            self.stub(name, "exit 0\n")
        result = subprocess.run([ZSH, "-f", "-c",
            'source "$1"; eval "fd --version"; eval "bat --version"; '
            'sh -c "$FZF_DEFAULT_COMMAND"; sh -c "$FZF_ALT_C_COMMAND"',
            "test", str(ROOT / "home/dot_zshrc")], env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.commands().splitlines(), [
            "fdfind --version", "batcat --version",
            "fdfind --type f --hidden --follow --exclude .git",
            "fdfind --type d --hidden --follow --exclude .git"])

    def test_linux_login_does_not_initialize_brew(self):
        result = subprocess.run([ZSH, "-f", "-c", 'OSTYPE=linux-gnu; source "$1"; true',
            "test", str(ROOT / "home/dot_zprofile")], env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.commands(), "")

    def test_ubuntu_update_alias_uses_apt(self):
        result = subprocess.run([ZSH, "-f", "-c",
            'OSTYPE=linux-gnu; source "$1"; eval update; alias brewup',
            "test", str(ROOT / "home/dot_aliases")], env=self.env, text=True, capture_output=True)
        self.assertNotEqual(result.returncode, 0)  # brewup must not exist on Ubuntu.
        self.assertEqual(self.commands().splitlines(), [
            "sudo apt-get update", "apt-get update", "sudo apt-get upgrade", "apt-get upgrade"])

    def test_managed_files_exclude_mac_only_apps_on_linux(self):
        for system in ("darwin", "linux"):
            with self.subTest(system=system):
                data = {"chezmoi": {"os": system, "osRelease": {"id": "ubuntu"}},
                        "name": "CI", "email": "ci@example.invalid", "personal": True, "work": False}
                output = subprocess.check_output([
                    CHEZMOI, "--source", str(ROOT), "--config", str(self.config),
                    "--destination", str(self.base), "--override-data", json.dumps(data),
                    "managed", "--exclude=externals", "--path-style=relative"], text=True)
                paths = output.splitlines()
                for app in (".hammerspoon/init.lua", ".config/iterm2/com.googlecode.iterm2.plist",
                            ".config/raycast/scripts/quick-capture.sh"):
                    self.assertEqual(app in paths, system == "darwin", app)
                self.assertIn(".config/nvim/init.lua", paths)
                self.assertIn(".config/ghostty/config.ghostty", paths)

    def test_mise_preserves_mac_and_scopes_runtime_changes_to_ubuntu(self):
        original = '# ~/.config/mise/config.toml\n# Managed by chezmoi — global default runtimes (replaces nvm/pyenv/brew runtimes)\n[tools]\nnode = "lts"\npython = "3.12"\ngo = "latest"\nruby = "latest"\npnpm = "latest"\nyarn = "latest"\njava = "temurin-21"\n\n[settings.ruby]\ncompile = false\n'
        for system, distro in (("darwin", ""), ("linux", "fedora")):
            with self.subTest(system=system, distro=distro):
                self.assertEqual(self.render("home/dot_config/mise/config.toml.tmpl",
                                            system=system, distro=distro), original)
        expected = tomllib.loads(original)
        del expected["tools"]["yarn"]
        del expected["tools"]["pnpm"]
        expected["tools"].update({"rust": "stable", "bun": "latest", "aqua:pnpm/pnpm": "latest"})
        expected["settings"].update(node={"compile": False}, python={"compile": False})
        for work in (False, True):
            with self.subTest(work=work):
                rendered = self.render("home/dot_config/mise/config.toml.tmpl", work=work)
                self.assertEqual(tomllib.loads(rendered), expected)

    def test_rendered_shell_templates_pass_shellcheck(self):
        for system, distro in (("darwin", ""), ("linux", "ubuntu"), ("linux", "fedora")):
            for work in (False, True):
                with self.subTest(system=system, work=work):
                    script = self.base / "packages.sh"
                    script.write_text(self.render(
                        "home/.chezmoiscripts/run_onchange_20-install-pkgs.sh.tmpl", system=system, distro=distro, work=work))
                    subprocess.run([SHELLCHECK, str(script)], check=True, capture_output=True, text=True)


if __name__ == "__main__":
    unittest.main()
