"""Run the remote wl-paste shim against a fake forwarded clipboard socket."""
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import threading
import unittest

ROOT = Path(__file__).resolve().parents[1]
SHIM = ROOT / "home/dot_local/bin/executable_wl-paste"
PNG = b"\x89PNG\r\n\x1a\n" + b"\x00" * 24


@unittest.skipUnless(shutil.which("nc") and shutil.which("bash"), "needs nc and bash")
class WlPasteShimTests(unittest.TestCase):
    def serve(self, payload):
        """Listen where ssht puts its forward and answer each connection with payload."""
        fd, path = tempfile.mkstemp(prefix="ssht-clip-test-", suffix=".sock", dir="/tmp")
        os.close(fd)
        os.unlink(path)
        server = socket.socket(socket.AF_UNIX)
        server.bind(path)
        server.listen(4)
        self.addCleanup(os.unlink, path)
        self.addCleanup(server.close)

        def loop():
            while True:
                try:
                    conn, _ = server.accept()
                except OSError:
                    return
                conn.sendall(payload)
                conn.close()

        threading.Thread(target=loop, daemon=True).start()

    def shim(self, *args):
        return subprocess.run(["bash", str(SHIM), *args], capture_output=True, timeout=20)

    def test_lists_and_serves_a_png(self):
        self.serve(PNG)
        listed = self.shim("-l")
        self.assertEqual((listed.returncode, listed.stdout), (0, b"image/png\n"))
        got = self.shim("--type", "image/png")
        self.assertEqual((got.returncode, got.stdout), (0, PNG))

    def test_fails_when_the_clipboard_holds_no_image(self):
        self.serve(b"")
        self.assertNotEqual(self.shim("-l").returncode, 0)
        self.assertNotEqual(self.shim("--type", "image/png").returncode, 0)

    def test_never_serves_text(self):
        self.serve(PNG)
        self.assertNotEqual(self.shim("--no-newline").returncode, 0)


if __name__ == "__main__":
    unittest.main()
