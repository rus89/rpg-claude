#!/usr/bin/env bash
# ABOUTME: Shell script that automates Play Store screenshot capture across 3 Android emulators.
# ABOUTME: Manages AVD lifecycle: boot, capture, shutdown. Writes PNGs to assets/screenshots/raw/.

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
# ABI auto-detected from host: arm64 → arm64-v8a, x86_64 → x86_64.
HOST_ARCH=$(uname -m)
case "$HOST_ARCH" in
  arm64)    ABI="arm64-v8a" ;;
  x86_64)   ABI="x86_64" ;;
  *)
    echo "ERROR: Unsupported host architecture: $HOST_ARCH" >&2
    exit 1
    ;;
esac
SYSTEM_IMAGE="system-images;android-34;google_apis;${ABI}"

# Bash 3.2 (default on macOS) lacks associative arrays. Use a case function.
avd_name_for() {
  case "$1" in
    phone)     echo "screenshot_phone" ;;
    tablet_7)  echo "screenshot_tablet_7" ;;
    tablet_10) echo "screenshot_tablet_10" ;;
  esac
}

# ---------------------------------------------------------------------------
# --setup: create AVDs idempotently
# ---------------------------------------------------------------------------
cmd_setup() {
  echo "NOTE: The system image must be installed before creating AVDs. Run:"
  echo "  sdkmanager \"${SYSTEM_IMAGE}\""
  echo ""

  avdmanager list avd | grep -q "screenshot_phone" || \
    avdmanager create avd -n "screenshot_phone" -k "${SYSTEM_IMAGE}" -d "pixel_7"

  avdmanager list avd | grep -q "screenshot_tablet_7" || \
    avdmanager create avd -n "screenshot_tablet_7" -k "${SYSTEM_IMAGE}" -d "Nexus 7 2013"

  avdmanager list avd | grep -q "screenshot_tablet_10" || \
    avdmanager create avd -n "screenshot_tablet_10" -k "${SYSTEM_IMAGE}" -d "pixel_tablet"

  echo "AVD setup complete."
}

# ---------------------------------------------------------------------------
# Run screenshot capture for a single device key (phone | tablet_7 | tablet_10)
# ---------------------------------------------------------------------------
run_device() {
  local device_key="$1"
  local avd_name
  avd_name=$(avd_name_for "$device_key")
  local device_name="$device_key"

  echo ""
  echo "=== Processing device: ${device_name} (AVD: ${avd_name}) ==="

  # Capture the set of emulator serials BEFORE boot. Sequential runs can leave
  # a not-yet-fully-shutdown prior serial in `adb devices`; diffing pre vs
  # post isolates the serial that belongs to this boot.
  local pre_serials
  pre_serials=$(adb devices | grep 'emulator-' | awk '{print $1}' | sort || true)

  # Boot emulator in background; save PID for cleanup trap.
  emulator -avd "${avd_name}" &
  local EMULATOR_PID=$!
  trap "kill $EMULATOR_PID 2>/dev/null || true" EXIT

  # Poll for emulator serial. `adb wait-for-device` is unreliable — it returns
  # for any transport, including already-dead serials.
  local DEVICE_ID=""
  local appear_waited=0
  while [ -z "$DEVICE_ID" ]; do
    sleep 3
    appear_waited=$((appear_waited + 3))
    local current_serials
    current_serials=$(adb devices | grep 'emulator-' | awk '{print $1}' | sort || true)
    DEVICE_ID=$(comm -23 <(echo "$current_serials") <(echo "$pre_serials") | head -1)
    if [ "$appear_waited" -ge 120 ] && [ -z "$DEVICE_ID" ]; then
      echo "ERROR: Emulator did not appear in adb devices within 2 minutes"
      exit 1
    fi
  done

  echo "Detected emulator: ${DEVICE_ID}. Waiting for full Android boot..."

  # adb wait-for-device ≠ boot complete. Poll sys.boot_completed.
  local waited=0
  until adb -s "$DEVICE_ID" shell getprop sys.boot_completed 2>/dev/null | grep -q '1'; do
    sleep 3
    waited=$((waited + 3))
    if [ "$waited" -ge 300 ]; then
      echo "ERROR: Emulator ${DEVICE_ID} did not boot within 5 minutes"
      adb -s "$DEVICE_ID" emu kill 2>/dev/null || true
      exit 1
    fi
  done

  echo "Device ${DEVICE_ID} fully booted. Running flutter drive..."

  # The test emits `<<SCREENSHOT>>name<<>>` marker lines via debugPrint at each
  # capture point. We watch flutter drive's stdout for those markers and fire
  # `adb exec-out screencap -p` to grab the live rendered surface — bypassing
  # FlutterImageView, which would otherwise suppress network-sourced tile bitmaps.
  mkdir -p "assets/screenshots/raw/${device_name}"
  SCREENSHOT_DEVICE_NAME="$device_name" flutter drive \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/screenshot_test.dart \
    --no-enable-impeller \
    -d "$DEVICE_ID" 2>&1 | while IFS= read -r line; do
      echo "$line"
      if [[ "$line" == *"<<SCREENSHOT>>"* ]]; then
        shot_name=$(echo "$line" | sed -E 's/.*<<SCREENSHOT>>([A-Za-z0-9_]+)<<>>.*/\1/')
        echo "[pipeline] capturing ${shot_name} on ${DEVICE_ID}..."
        adb -s "$DEVICE_ID" exec-out screencap -p \
          > "assets/screenshots/raw/${device_name}/${shot_name}.png" \
          || echo "[pipeline] WARNING: screencap failed for ${shot_name}"
      fi
    done

  # `while read` runs in a subshell, so PIPESTATUS reflects flutter drive's exit.
  local DRIVE_EXIT=${PIPESTATUS[0]}
  if [ "$DRIVE_EXIT" -ne 0 ]; then
    echo "ERROR: flutter drive exited with code ${DRIVE_EXIT}"
    adb -s "$DEVICE_ID" emu kill 2>/dev/null || true
    exit "$DRIVE_EXIT"
  fi

  echo "flutter drive complete. Shutting down ${DEVICE_ID}..."

  adb -s "$DEVICE_ID" emu kill
  local shutdown_waited=0
  until ! adb devices | grep -q "$DEVICE_ID"; do
    sleep 2
    shutdown_waited=$((shutdown_waited + 2))
    if [ "$shutdown_waited" -ge 60 ]; then
      echo "WARNING: Emulator ${DEVICE_ID} did not stop within 60 seconds, continuing"
      break
    fi
  done

  trap - EXIT
  echo "Device ${DEVICE_ID} stopped."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  local arg="${1:-}"

  if [ "$arg" = "--setup" ]; then
    cmd_setup
    exit 0
  fi

  if [ -z "$arg" ]; then
    run_device "phone"
    run_device "tablet_7"
    run_device "tablet_10"
  elif [ "$arg" = "phone" ] || [ "$arg" = "tablet_7" ] || [ "$arg" = "tablet_10" ]; then
    run_device "$arg"
  else
    echo "Usage: $0 [--setup | phone | tablet_7 | tablet_10]"
    exit 1
  fi

  echo ""
  echo "Screenshot capture complete."
}

main "$@"
