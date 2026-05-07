#!/usr/bin/env bash
set -euo pipefail

if (( $# == 0 )); then
  echo "Usage: switch-profile [FLAGS...] <profile-name>" >&2
  exit 1
fi

while (( $# > 1 )); do
  case "$1" in
    -b)
      shift
      if (( $# < 2 )); then
        echo "switch-profile: -b requires an argument" >&2
        exit 1
      fi
      export HOME_MANAGER_BACKUP_EXT="$1"
      ;;
    -n|--dry-run)
      export DRY_RUN=1
      ;;
    --show-trace)
      export VERBOSE=1
      ;;
    *)
      echo "switch-profile: unknown flag '$1'" >&2
      exit 1
      ;;
  esac
  shift
done

PROFILE_NAME="$1"

if [[ "$PROFILE_NAME" == -* ]]; then
  if [[ "$PROFILE_NAME" == "-b" ]]; then
    echo "switch-profile: -b requires an argument" >&2
  else
    echo "switch-profile: missing profile name" >&2
  fi
  exit 1
fi

DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/cabanashmul"
RESULT_LINK="$DATA_DIR/result-$PROFILE_NAME"

if [ ! -e "$RESULT_LINK" ]; then
  echo "switch-profile: no pre-built result for '$PROFILE_NAME'" >&2
  echo "Run build-profiles from your cabanashmul directory first." >&2
  exit 1
fi

echo "Activating profile: $PROFILE_NAME"
exec "$RESULT_LINK/activate" --driver-version 1
