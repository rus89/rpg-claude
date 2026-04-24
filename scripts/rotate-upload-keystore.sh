#!/usr/bin/env bash
# ABOUTME: Rotates an Android upload-keystore store password to a fresh random
# ABOUTME: value and stores the new password in macOS Keychain. Interactive.

set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage: $0 <keystore-path> <keychain-service-name>

Rotates the store password of an upload keystore (PKCS12 or JKS) to a random
value generated with openssl, then stores the new password in macOS Keychain
under the given service name (account = \$USER).

Example:
  $0 ~/Documents/Projects/Keystores/App2/upload-keystore.jks app2-upload-keystore

The keystore file is modified in place. A timestamped backup is created next
to the original before any changes.
EOF
  exit 2
}

if [[ $# -ne 2 ]]; then
  usage
fi

KEYSTORE_PATH="$1"
KEYCHAIN_SERVICE="$2"

if [[ ! -f "$KEYSTORE_PATH" ]]; then
  echo "Error: keystore file not found: $KEYSTORE_PATH" >&2
  exit 1
fi

if [[ -z "$KEYCHAIN_SERVICE" ]]; then
  echo "Error: keychain service name cannot be empty" >&2
  exit 1
fi

for cmd in keytool openssl security pbcopy; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Error: required command not found on \$PATH: $cmd" >&2
    exit 1
  }
done

NEW_PW=""
trap 'unset NEW_PW STORE_PW 2>/dev/null || true' EXIT

BACKUP_PATH="${KEYSTORE_PATH}.backup-$(date +%Y%m%d-%H%M%S)"
echo "→ Backing up keystore: $BACKUP_PATH"
cp "$KEYSTORE_PATH" "$BACKUP_PATH"

NEW_PW=$(openssl rand -base64 24)
printf '%s' "$NEW_PW" | pbcopy

cat <<EOF

New password generated and copied to your clipboard.
You will paste it twice when keytool prompts for the new password.

If the clipboard gets overwritten, the password is also:

  $NEW_PW

EOF

read -r -p "Press Enter to start keytool -storepasswd..."

echo ""
echo "→ keytool -storepasswd"
echo "  Prompts:"
echo "    Enter keystore password         → OLD password"
echo "    New keystore password           → paste NEW (Cmd+V)"
echo "    Re-enter new keystore password  → paste NEW (Cmd+V)"
echo ""

if ! keytool -storepasswd -keystore "$KEYSTORE_PATH"; then
  echo "" >&2
  echo "Error: keytool -storepasswd failed. Keystore unchanged." >&2
  echo "Backup preserved at: $BACKUP_PATH" >&2
  exit 1
fi

echo ""
echo "→ Verifying keystore opens with the new password..."
if ! STORE_PW="$NEW_PW" keytool -list -keystore "$KEYSTORE_PATH" -storepass:env STORE_PW >/dev/null; then
  echo "" >&2
  echo "Error: keystore verification FAILED with the new password." >&2
  echo "Restore from backup if needed:" >&2
  echo "  cp '$BACKUP_PATH' '$KEYSTORE_PATH'" >&2
  exit 1
fi
unset STORE_PW

echo "→ Storing password in Keychain (service='$KEYCHAIN_SERVICE', account='$USER')"
security add-generic-password \
  -a "$USER" \
  -s "$KEYCHAIN_SERVICE" \
  -w "$NEW_PW" \
  -U

if ! security find-generic-password -a "$USER" -s "$KEYCHAIN_SERVICE" -w >/dev/null 2>&1; then
  echo "Error: Keychain entry created but could not be read back." >&2
  echo "Manual recovery:" >&2
  echo "  security add-generic-password -a \"\$USER\" -s \"$KEYCHAIN_SERVICE\" -w '<paste password>' -U" >&2
  exit 1
fi

cat <<EOF

✅ Rotation complete.

   Keystore: $KEYSTORE_PATH
   Backup:   $BACKUP_PATH  (delete manually once you've verified builds work)
   Keychain: service='$KEYCHAIN_SERVICE', account='$USER'

Clipboard is still holding the password. Clear it with:
  pbcopy </dev/null

Test retrieval:
  security find-generic-password -a "\$USER" -s "$KEYCHAIN_SERVICE" -w
EOF
