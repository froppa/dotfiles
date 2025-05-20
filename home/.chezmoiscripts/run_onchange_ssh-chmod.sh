#!/bin/bash
set -euo pipefail

chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
chmod 644 ~/.ssh/*.pub || true
