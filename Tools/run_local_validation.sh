#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESTINATION="${1:-platform=iOS Simulator,name=iPhone 17}"
DERIVED_DATA_ROOT="${DERIVED_DATA_ROOT:-/tmp/PulsecraftLocalValidation}"
APP_DERIVED_DATA_PATH="$DERIVED_DATA_ROOT/Metronome"
APP_BUNDLE_ID="com.seanashe.metronome"
MIN_LAUNCH_SCREENSHOT_BYTES=150000
DISALLOWED_LOCAL_FIRST_PATTERN='URLSession|http://|https://|SKPayment|StoreKit|AdSupport|AppTrackingTransparency|Firebase|Analytics|CloudKit|CKContainer|subscription|subscribe|account|sign in|login|tracking|track'

cd "$ROOT_DIR"

echo "Local validation destination: $DESTINATION"
echo "Derived data root: $DERIVED_DATA_ROOT"

echo
echo "== Privacy and local-first policy =="
plutil -lint App/PrivacyInfo.xcprivacy

privacy_json="$(plutil -convert json -o - App/PrivacyInfo.xcprivacy)"
/usr/bin/ruby -rjson -e '
  manifest = JSON.parse(ARGF.read)
  failures = []
  failures << "NSPrivacyTracking must be false" unless manifest["NSPrivacyTracking"] == false
  failures << "NSPrivacyCollectedDataTypes must be empty" unless manifest["NSPrivacyCollectedDataTypes"] == []
  failures << "NSPrivacyTrackingDomains must be empty" unless manifest["NSPrivacyTrackingDomains"] == []
  failures << "NSPrivacyAccessedAPITypes must be empty" unless manifest["NSPrivacyAccessedAPITypes"] == []
  if failures.any?
    warn failures.join("\n")
    exit 1
  end
' <<< "$privacy_json"

if rg -n '\.package\(' Package.swift; then
  echo "Package.swift declares external dependencies; review v1 dependency policy before release." >&2
  exit 1
fi

if disallowed_hits="$(rg -n "$DISALLOWED_LOCAL_FIRST_PATTERN" App Sources Package.swift Tests -g '*.swift')"; then
  echo "Potential account, tracking, analytics, network, cloud, ad, or subscription surface found:" >&2
  echo "$disallowed_hits" >&2
  exit 1
fi

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
  -derivedDataPath "$APP_DERIVED_DATA_PATH" \
  -quiet

echo
echo "== Simulator app launch smoke =="
simulator_name="$(
  /usr/bin/ruby -e 'destination = ARGV.fetch(0); match = destination.match(/(?:^|,)name=([^,]+)/); puts(match[1]) if match' "$DESTINATION"
)"

if [[ -z "$simulator_name" ]]; then
  echo "Destination must include a simulator name for launch smoke validation." >&2
  exit 1
fi

simulator_udid="$(
  xcrun simctl list devices available -j | /usr/bin/ruby -rjson -e '
    name = ARGV.fetch(0)
    devices = JSON.parse($stdin.read).fetch("devices")
    devices.each_value do |runtime_devices|
      match = runtime_devices.find { |device| device["name"] == name && device["isAvailable"] }
      if match
        puts match.fetch("udid")
        exit
      end
    end
  ' "$simulator_name"
)"

if [[ -z "$simulator_udid" ]]; then
  echo "No available simulator found named '$simulator_name'." >&2
  exit 1
fi

app_path="$APP_DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/Pulsecraft.app"
launch_screenshot="$APP_DERIVED_DATA_PATH/launch-smoke.png"

xcrun simctl boot "$simulator_udid" 2>/dev/null || true
xcrun simctl bootstatus "$simulator_udid" -b
xcrun simctl install "$simulator_udid" "$app_path"
xcrun simctl launch "$simulator_udid" "$APP_BUNDLE_ID"
sleep 8
xcrun simctl io "$simulator_udid" screenshot "$launch_screenshot" >/dev/null
xcrun simctl terminate "$simulator_udid" "$APP_BUNDLE_ID" >/dev/null 2>&1 || true

if [[ ! -s "$launch_screenshot" ]]; then
  echo "Launch smoke screenshot was not created." >&2
  exit 1
fi

screenshot_bytes="$(stat -f '%z' "$launch_screenshot")"

if (( screenshot_bytes < MIN_LAUNCH_SCREENSHOT_BYTES )); then
  echo "Launch smoke screenshot looks blank or incomplete: $launch_screenshot ($screenshot_bytes bytes)." >&2
  exit 1
fi

echo "Launch smoke screenshot: $launch_screenshot"

echo
echo "Local validation passed."
