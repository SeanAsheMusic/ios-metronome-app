#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESTINATION="${1:-platform=iOS Simulator,name=iPhone 17}"
DERIVED_DATA_ROOT="${DERIVED_DATA_ROOT:-/tmp/PulsecraftLocalValidation}"
APP_DERIVED_DATA_PATH="$DERIVED_DATA_ROOT/Metronome"
APP_BUNDLE_ID="com.seanashe.metronome"
MIN_SCREENSHOT_BYTES=150000
DISALLOWED_LOCAL_FIRST_PATTERN='URLSession|http://|https://|SKPayment|StoreKit|AdSupport|AppTrackingTransparency|Firebase|Analytics|CloudKit|CKContainer|subscription|subscribe|account|sign in|login|tracking|track'
BUILD_LOG_ROOT="$DERIVED_DATA_ROOT/Logs"
ARCHIVE_PATH="$DERIVED_DATA_ROOT/Pulsecraft.xcarchive"

cd "$ROOT_DIR"
mkdir -p "$BUILD_LOG_ROOT"

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

run_xcode_and_reject_warnings() {
  local log_path="$1"
  shift

  "$@" 2>&1 | tee "$log_path"

  if warning_hits="$(rg -n "warning:" "$log_path")"; then
    echo "Xcode emitted warnings; resolve them before release-candidate validation:" >&2
    echo "$warning_hits" >&2
    exit 1
  fi
}

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
  local log_path="$BUILD_LOG_ROOT/${scheme}-test.log"

  echo
  echo "== Xcode tests: $scheme =="
  run_xcode_and_reject_warnings "$log_path" \
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
run_xcode_test MetronomeUITests

echo
echo "== Simulator app build =="
run_xcode_and_reject_warnings "$BUILD_LOG_ROOT/Metronome-build.log" \
  xcodebuild build \
  -project Metronome.xcodeproj \
  -scheme Metronome \
  -destination "$DESTINATION" \
  CODE_SIGNING_ALLOWED=NO \
  -derivedDataPath "$APP_DERIVED_DATA_PATH" \
  -quiet

echo
echo "== Generic iOS device build =="
run_xcode_and_reject_warnings "$BUILD_LOG_ROOT/Metronome-device-build.log" \
  xcodebuild build \
  -project Metronome.xcodeproj \
  -scheme Metronome \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  -derivedDataPath "$DERIVED_DATA_ROOT/MetronomeDevice" \
  -quiet

echo
echo "== Unsigned generic iOS archive =="
rm -rf "$ARCHIVE_PATH"
run_xcode_and_reject_warnings "$BUILD_LOG_ROOT/Metronome-archive.log" \
  xcodebuild archive \
  -project Metronome.xcodeproj \
  -scheme Metronome \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  SKIP_INSTALL=NO \
  -archivePath "$ARCHIVE_PATH" \
  -derivedDataPath "$DERIVED_DATA_ROOT/MetronomeArchive" \
  -quiet

if [[ ! -d "$ARCHIVE_PATH/Products/Applications/Pulsecraft.app" ]]; then
  echo "Archive did not contain Pulsecraft.app." >&2
  exit 1
fi

archived_app_path="$ARCHIVE_PATH/Products/Applications/Pulsecraft.app"
archived_info_plist="$archived_app_path/Info.plist"
archived_privacy_manifest="$archived_app_path/PrivacyInfo.xcprivacy"

/usr/bin/ruby -rjson -e '
  info_plist = ARGV.fetch(0)
  info = JSON.parse(`plutil -convert json -o - "#{info_plist}"`)
  failures = []
  failures << "CFBundleDisplayName must be Pulsecraft" unless info["CFBundleDisplayName"] == "Pulsecraft"
  failures << "CFBundleIdentifier must be com.seanashe.metronome" unless info["CFBundleIdentifier"] == "com.seanashe.metronome"
  failures << "CFBundleShortVersionString must be 0.1.0" unless info["CFBundleShortVersionString"] == "0.1.0"
  failures << "CFBundleVersion must be 1" unless info["CFBundleVersion"] == "1"
  failures << "MinimumOSVersion must be 17.0" unless info["MinimumOSVersion"] == "17.0"
  failures << "LSApplicationCategoryType must be public.app-category.music" unless info["LSApplicationCategoryType"] == "public.app-category.music"
  failures << "UIBackgroundModes must include audio" unless Array(info["UIBackgroundModes"]).include?("audio")
  failures << "UIDeviceFamily must include iPhone and iPad" unless info["UIDeviceFamily"] == [1, 2]
  if failures.any?
    warn failures.join("\n")
    exit 1
  end
' "$archived_info_plist"

if [[ ! -f "$archived_privacy_manifest" ]]; then
  echo "Archive did not contain PrivacyInfo.xcprivacy." >&2
  exit 1
fi

archived_privacy_json="$(plutil -convert json -o - "$archived_privacy_manifest")"
/usr/bin/ruby -rjson -e '
  manifest = JSON.parse(ARGF.read)
  failures = []
  failures << "Archived NSPrivacyTracking must be false" unless manifest["NSPrivacyTracking"] == false
  failures << "Archived NSPrivacyCollectedDataTypes must be empty" unless manifest["NSPrivacyCollectedDataTypes"] == []
  failures << "Archived NSPrivacyTrackingDomains must be empty" unless manifest["NSPrivacyTrackingDomains"] == []
  failures << "Archived NSPrivacyAccessedAPITypes must be empty" unless manifest["NSPrivacyAccessedAPITypes"] == []
  if failures.any?
    warn failures.join("\n")
    exit 1
  end
' <<< "$archived_privacy_json"

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
edit_screenshot="$APP_DERIVED_DATA_PATH/edit-rhythm-grid-smoke.png"
settings_screenshot="$APP_DERIVED_DATA_PATH/settings-smoke.png"

capture_app_screenshot() {
  local screenshot_path="$1"
  shift

  xcrun simctl launch "$simulator_udid" "$APP_BUNDLE_ID" "$@"
  sleep 8
  xcrun simctl io "$simulator_udid" screenshot "$screenshot_path" >/dev/null
  xcrun simctl terminate "$simulator_udid" "$APP_BUNDLE_ID" >/dev/null 2>&1 || true

  if [[ ! -s "$screenshot_path" ]]; then
    echo "Smoke screenshot was not created: $screenshot_path" >&2
    exit 1
  fi

  screenshot_bytes="$(stat -f '%z' "$screenshot_path")"

  if (( screenshot_bytes < MIN_SCREENSHOT_BYTES )); then
    echo "Smoke screenshot looks blank or incomplete: $screenshot_path ($screenshot_bytes bytes)." >&2
    exit 1
  fi
}

xcrun simctl boot "$simulator_udid" 2>/dev/null || true
xcrun simctl bootstatus "$simulator_udid" -b
xcrun simctl install "$simulator_udid" "$app_path"
capture_app_screenshot "$launch_screenshot"
capture_app_screenshot "$edit_screenshot" -PulsecraftUITestingInMemoryLibrary -PulsecraftInitialTab edit
capture_app_screenshot "$settings_screenshot" -PulsecraftUITestingInMemoryLibrary -PulsecraftInitialTab settings

echo "Launch smoke screenshot: $launch_screenshot"
echo "Edit rhythm grid smoke screenshot: $edit_screenshot"
echo "Settings smoke screenshot: $settings_screenshot"

echo
echo "Local validation passed."
