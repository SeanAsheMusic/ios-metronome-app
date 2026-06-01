#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESTINATION="${1:-platform=iOS Simulator,name=iPhone 17}"
DERIVED_DATA_ROOT="${DERIVED_DATA_ROOT:-/tmp/PulsecraftLocalValidation}"

cd "$ROOT_DIR"

echo "Local validation destination: $DESTINATION"
echo "Derived data root: $DERIVED_DATA_ROOT"

echo
echo "== Swift package tests =="
swift test

echo
echo "== Click fixture checksums =="
(
  cd SoundLibrary/RenderedVerification
  shasum -a 256 -c SHA256SUMS
)

run_xcode_test() {
  local scheme="$1"
  local derived_data_path="$DERIVED_DATA_ROOT/$scheme"

  echo
  echo "== Xcode tests: $scheme =="
  xcodebuild test \
    -project Metronome.xcodeproj \
    -scheme "$scheme" \
    -destination "$DESTINATION" \
    CODE_SIGNING_ALLOWED=NO \
    -derivedDataPath "$derived_data_path" \
    -quiet
}

run_xcode_test RhythmModel
run_xcode_test AudioEngine
run_xcode_test Persistence

echo
echo "== Simulator app build =="
xcodebuild build \
  -project Metronome.xcodeproj \
  -scheme Metronome \
  -destination "$DESTINATION" \
  CODE_SIGNING_ALLOWED=NO \
  -derivedDataPath "$DERIVED_DATA_ROOT/Metronome" \
  -quiet

echo
echo "Local validation passed."
