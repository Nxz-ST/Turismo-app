#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

exec claude \
  --name rutaamiga \
  --permission-mode plan \
  --add-dir \
    ../turismo_backend \
    ../rutaamiga_admin
