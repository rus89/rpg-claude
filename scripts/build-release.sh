#!/usr/bin/env bash
# ABOUTME: Release build wrapper that fetches the upload-keystore password from
# ABOUTME: macOS Keychain and runs `flutter build appbundle` with obfuscation enabled.

set -euo pipefail

KEYCHAIN_SERVICE="rpg-claude-upload-keystore"

if ! PW=$(security find-generic-password -a "$USER" -s "$KEYCHAIN_SERVICE" -w 2>/dev/null); then
  echo "Error: upload-keystore password not found in macOS Keychain." >&2
  echo "Expected: service='$KEYCHAIN_SERVICE', account='$USER'." >&2
  echo "Store it with:" >&2
  echo "  security add-generic-password -a \"\$USER\" -s \"$KEYCHAIN_SERVICE\" -w <password> -U" >&2
  exit 1
fi

export RELEASE_STORE_PASSWORD="$PW"
export RELEASE_KEY_PASSWORD="$PW"

flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/debug-info/
