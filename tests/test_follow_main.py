"""Exercise follow-main.sh against local Git remotes and fake chezmoi, mise and systemctl."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "home/dot_local/bin/executable_follow-main.sh"


class FollowMainTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles follow-main-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.home = self.base / "home"
        self.bin = self.base / "bin"
        self.bin.mkdir(parents=True)
        self.log = self.base / "commands"
        self.status = self.base / "chezmoi-status"
        self.status.write_text("")
        self.dotfiles = self.clone("dotfiles", self.base / "chezmoi", "master")
        (self.dotfiles / "home").mkdir()
        self.verk = self.clone("verk", self.home / "code/verk", "main")
        self.env = dict(
            os.environ, HOME=str(self.home), PATH=f"{self.bin}:/usr/bin:/bin",
            TEST_LOG=str(self.log), DOTFILES=str(self.dotfiles), STATUS=str(self.status),
            GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_NOSYSTEM="1")
        # chezmoi update pulls the source, then applies; the fake only pulls.
        self.stub("chezmoi", 'printf "chezmoi %s\\n" "$*" >> "$TEST_LOG"\n'
                  'case $1 in\n'
                  '  source-path) printf "%s/home\\n" "$DOTFILES" ;;\n'
                  '  status) [ -z "${FAIL_STATUS:-}" ] || exit "$FAIL_STATUS"; cat "$STATUS" ;;\n'
                  '  update) [ -z "${FAIL_UPDATE:-}" ] || exit "$FAIL_UPDATE"\n'
                  '    git -C "$DOTFILES" pull -q --ff-only ;;\n'
                  '  *) exit 64 ;;\n'
                  'esac\n')
        self.stub("systemctl", 'printf "systemctl %s\\n" "$*" >> "$TEST_LOG"\n')
        self.stub("mise", 'printf "mise %s in %s\\n" "$*" "$PWD" >> "$TEST_LOG"\n'
                  'exit "${INSTALL_RC:-0}"\n')

    def git(self, *args, cwd=None):
        return subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=True, text=True,
                              env=dict(os.environ, GIT_CONFIG_GLOBAL="/dev/null",
                                       GIT_CONFIG_NOSYSTEM="1")).stdout.strip()

    def commit(self, repo, name):
        (repo / name).write_text(name)
        self.git("add", name, cwd=repo)
        self.git("-c", "user.name=t", "-c", "user.email=t@example.invalid",
                 "-c", "commit.gpgsign=false", "commit", "-qm", name, cwd=repo)

    def clone(self, name, path, branch):
        seed = self.base / f"{name}-seed"
        self.git("init", "-q", "-b", branch, str(seed))
        self.commit(seed, "one")
        self.git("clone", "-q", "--bare", str(seed), str(self.base / f"{name}.git"))
        self.git("clone", "-q", str(self.base / f"{name}.git"), str(path))
        return path

    def advance(self, name):
        """Commit upstream so the next pull has something to fetch."""
        seed = self.base / f"{name}-seed"
        self.commit(seed, "two")
        self.git("push", "-q", str(self.base / f"{name}.git"), "HEAD", cwd=seed)
        return self.git("rev-parse", "HEAD", cwd=seed)

    def stub(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/sh\nset -eu\n" + body)
        path.chmod(0o755)

    def run_script(self, *args, **env):
        return subprocess.run(["/bin/sh", str(SCRIPT), *args], env=dict(self.env, **env),
                              capture_output=True, text=True)

    def commands(self):
        return self.log.read_text() if self.log.exists() else ""

    def head(self, repo):
        return self.git("rev-parse", "HEAD", cwd=repo)

    def test_updates_dotfiles_and_installs_verk(self):
        dotfiles_tip, verk_tip = self.advance("dotfiles"), self.advance("verk")
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.head(self.dotfiles), dotfiles_tip)
        self.assertEqual(self.head(self.verk), verk_tip)
        self.assertIn("chezmoi update --exclude=scripts --no-tty", self.commands())
        self.assertIn("systemctl --user daemon-reload", self.commands())
        self.assertIn(f"mise exec -- depot exec -- ./scripts/install-linux.sh in {self.verk}",
                      self.commands())

    def test_target_drift_skips_dotfiles_but_not_verk(self):
        dotfiles_before = self.head(self.dotfiles)
        self.advance("dotfiles")
        verk_tip = self.advance("verk")
        self.status.write_text(" M .zshrc\nMM .gitconfig\nDA .vimrc\n")
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("changed since chezmoi last wrote them", result.stderr)
        self.assertIn("MM .gitconfig\nDA .vimrc\n", result.stderr)
        self.assertNotIn(" M .zshrc", result.stderr)
        self.assertEqual(self.head(self.dotfiles), dotfiles_before)
        self.assertNotIn("chezmoi update", self.commands())
        self.assertNotIn("systemctl", self.commands())
        self.assertEqual(self.head(self.verk), verk_tip)
        self.assertIn("mise exec", self.commands())

    def test_pending_source_changes_are_not_drift(self):
        tip = self.advance("dotfiles")
        self.status.write_text(" M .zshrc\n A .config/new\n")
        result = self.run_script("dotfiles")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.head(self.dotfiles), tip)

    def test_verk_off_main_is_left_alone(self):
        self.git("switch", "-qc", "feature", cwd=self.verk)
        before = self.head(self.verk)
        self.advance("verk")
        result = self.run_script("verk")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("is not on main", result.stderr)
        self.assertEqual(self.head(self.verk), before)
        self.assertNotIn("mise", self.commands())

    def test_dotfiles_off_master_is_left_alone(self):
        self.git("switch", "-qc", "feature", cwd=self.dotfiles)
        result = self.run_script("dotfiles")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("is not on master", result.stderr)
        self.assertNotIn("chezmoi status", self.commands())
        self.assertNotIn("chezmoi update", self.commands())

    def test_dirty_checkouts_are_left_alone(self):
        (self.dotfiles / "scratch").write_text("x")
        (self.verk / "scratch").write_text("x")
        before = self.head(self.verk)
        self.advance("verk")
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.head(self.verk), before)
        self.assertNotIn("chezmoi update", self.commands())
        self.assertNotIn("mise", self.commands())

    def test_current_verk_is_not_reinstalled(self):
        (self.home / ".verk").mkdir()
        (self.home / ".verk/installed.commit").write_text(self.head(self.verk) + "\n")
        result = self.run_script("verk")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("mise", self.commands())

    def test_dotfiles_failure_is_reported_and_verk_still_runs(self):
        for failure in ({"FAIL_STATUS": "7"}, {"FAIL_UPDATE": "7"}):
            with self.subTest(**failure):
                self.log.unlink(missing_ok=True)
                result = self.run_script(**failure)
                self.assertEqual(result.returncode, 7, result.stderr)
                self.assertNotIn("systemctl", self.commands())
                self.assertIn("mise exec", self.commands())

    def test_verk_pull_failure_propagates(self):
        self.git("remote", "set-url", "origin", str(self.base / "missing.git"), cwd=self.verk)
        result = self.run_script()
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertNotIn("mise", self.commands())

    def test_install_exit_codes(self):
        for rc, expected in (("3", 0), ("4", 0), ("9", 9)):
            with self.subTest(rc=rc):
                result = self.run_script("verk", INSTALL_RC=rc)
                self.assertEqual(result.returncode, expected, result.stderr)

    def test_unknown_step_is_a_usage_error(self):
        result = self.run_script("everything")
        self.assertEqual(result.returncode, 2)
        self.assertEqual(self.commands(), "")


if __name__ == "__main__":
    unittest.main()
