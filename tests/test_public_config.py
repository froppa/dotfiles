"""Exercise publication boundaries without using real machine or secret data."""

import importlib.util
from pathlib import Path
import unittest


spec = importlib.util.spec_from_file_location(
    "public_config", Path(__file__).resolve().parents[1] / "scripts/check-public-config.py"
)
check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(check)


class PublicConfigTests(unittest.TestCase):
    def test_rejects_machine_and_credential_data(self):
        for text in (
            "/Users/" + "example/private/config", "/home/" + "example/private/config",
            "op" + "://example/item/password", "ssh example@" + "host.example.invalid",
            "https://192.0." + "2.123/api", "100.64." + "0.42",
            "-----BEGIN " + "PRIVATE KEY-----", "ghp_" + "x" * 30,
        ):
            with self.subTest(text=text):
                self.assertTrue(check.findings("README.md", text))

    def test_allows_portable_paths_and_local_socket_bindings(self):
        self.assertFalse(check.findings(
            "README.md", "$HOME/.ssh/config.local /home/linuxbrew/.linuxbrew 127.0.0.1"
        ))

    def test_requires_review_for_new_managed_apps_and_commands(self):
        self.assertTrue(check.findings("home/dot_config/example/config.toml", ""))
        self.assertTrue(check.findings("home/dot_local/bin/executable_example", ""))
        self.assertFalse(check.findings("home/dot_config/tmux/tmux.conf", ""))

    def test_model_selection_stays_unmanaged(self):
        path = "home/dot_config/zed/private_settings.json"
        self.assertTrue(check.findings(path, '{"language_models": {}}'))
        self.assertTrue(check.findings(path, '{"agent": {"default_model": {}}}'))
        self.assertFalse(check.findings(path, '{"agent": {"button": true}}'))
