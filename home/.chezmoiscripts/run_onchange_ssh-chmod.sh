#!/bin/bash
set -euo pipefail

chmod 700 ~/.ssh
find ~/.ssh -type d -exec chmod 700 {} +
find ~/.ssh -type f -exec chmod 600 {} +
find ~/.ssh -type f -name '*.pub' -exec chmod 644 {} +
