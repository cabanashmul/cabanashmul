#!/usr/bin/env bash
set -euo pipefail

NO_BUILD=false
SWITCH_PROFILE=""

usage() {
  cat <<'EOF' >&2
Usage: update-cabanashmul [--no-build] [--switch <profile>]
EOF
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "update-cabanashmul: required command not found: $1" >&2
    exit 1
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --no-build)
      NO_BUILD=true
      shift
      ;;
    --switch)
      if [ $# -lt 2 ]; then
        echo "update-cabanashmul: --switch requires a profile argument" >&2
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
      echo "update-cabanashmul: unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [ "$NO_BUILD" = true ] && [ -n "$SWITCH_PROFILE" ]; then
  echo "update-cabanashmul: --switch cannot be used with --no-build" >&2
  exit 1
fi

need_cmd git

if ! git remote get-url template >/dev/null 2>&1; then
  echo "update-cabanashmul: missing required git remote 'template'" >&2
  echo "Run: nix run github:shmul95/cabanashmul#setup" >&2
  exit 1
fi

echo "Fetching template remote..."
git fetch template

echo "Merging template/main..."
git merge template/main

if [ "$NO_BUILD" = false ]; then
  need_cmd build-profiles
  echo "Rebuilding profiles..."
  build-profiles
fi

if [ -n "$SWITCH_PROFILE" ]; then
  need_cmd switch-profile
  echo "Switching to profile: $SWITCH_PROFILE"
  switch-profile "$SWITCH_PROFILE"
fi
