#!/usr/bin/env bash
set -euo pipefail

FLAKE_DIR="${CABANASHMUL_DIR:-$PWD}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/cabanashmul"
USERNAME="$(id -un)"
SWITCH_PROFILE=""

usage() {
  cat <<'EOF' >&2
Usage: build-profiles [--switch <profile>]
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -s|--switch)
      if [ $# -lt 2 ]; then
        echo "build-profiles: --switch requires a profile argument" >&2
        usage
        exit 1
      fi
      SWITCH_PROFILE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "build-profiles: unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

echo "Discovering profiles from: $FLAKE_DIR"
PROFILE_NAMES="$(
  HOME="$HOME" USER="$USERNAME" nix eval --impure --raw \
    "${FLAKE_DIR}#lib.profileNamesStr"
)"

if [ -z "$PROFILE_NAMES" ]; then
  echo "build-profiles: no profiles found in lib.profileNamesStr" >&2
  exit 1
fi

echo "Profiles: $PROFILE_NAMES"
mkdir -p "$DATA_DIR"
FAILED=()

for PROFILE in $PROFILE_NAMES; do
  CONFIG_ATTR="${USERNAME}-${PROFILE}"
  RESULT_LINK="$DATA_DIR/result-${PROFILE}"
  echo ""
  echo "==> $PROFILE  (homeConfigurations.${CONFIG_ATTR})"
  if HOME="$HOME" USER="$USERNAME" nix build --impure \
       "${FLAKE_DIR}#homeConfigurations.${CONFIG_ATTR}.activationPackage" \
       --out-link "$RESULT_LINK"; then
    echo "    -> $(readlink "$RESULT_LINK")"
  else
    echo "    FAILED: $PROFILE" >&2
    FAILED+=("$PROFILE")
  fi
done

echo ""
if [ ${#FAILED[@]} -gt 0 ]; then
  printf 'build-profiles: failed to build: %s\n' "${FAILED[@]}" >&2
  exit 1
fi

if [ -n "$SWITCH_PROFILE" ]; then
  echo "Switching to profile: $SWITCH_PROFILE"
  switch-profile "$SWITCH_PROFILE"
else
  echo "Done. Run: switch-profile <profile-name>"
fi
