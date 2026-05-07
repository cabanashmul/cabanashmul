#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$HOME/vault}"

if [ -n "${INIT_VAULT_TEMPLATE:-}" ]; then
  TEMPLATE_DIR="$INIT_VAULT_TEMPLATE"
else
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  TEMPLATE_DIR="${SCRIPT_DIR}/../vault-template"
fi

if [ -e "$TARGET_DIR" ]; then
  echo "init-vault: target already exists: $TARGET_DIR" >&2
  echo "init-vault: choose a new path instead of overwriting an existing vault." >&2
  exit 1
fi

mkdir -p "$(dirname -- "$TARGET_DIR")"

echo "Creating vault scaffold at: $TARGET_DIR"
cp -R "$TEMPLATE_DIR/." "$TARGET_DIR"

cat <<EOF

Next steps:
1. Edit local.nix and set programs.gsd.vault.path = "$TARGET_DIR".
2. Rebuild your Home Manager config.
3. Open the vault in Obsidian.

EOF
