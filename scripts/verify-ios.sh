#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! xcodebuild -version >/dev/null 2>&1; then
  printf '%s\n' '需要完整 Xcode、iOS SDK 和 iPhone/iPad 模拟器；当前只有 CommandLineTools。' >&2
  exit 2
fi
xcodebuild -project TreeSeaAssistant.xcodeproj -scheme TreeSeaAssistant \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project TreeSeaAssistant.xcodeproj -scheme TreeSeaAssistant -showdestinations
if [[ -z "${TREESEA_SIMULATOR_ID:-}" || -z "${TREESEA_IPAD_SIMULATOR_ID:-}" ]]; then
  printf '%s\n' '根据上面的真实设备 UUID 设置 TREESEA_SIMULATOR_ID 和 TREESEA_IPAD_SIMULATOR_ID，然后重跑。' >&2
  exit 3
fi
for device in "$TREESEA_SIMULATOR_ID" "$TREESEA_IPAD_SIMULATOR_ID"; do
  xcodebuild -project TreeSeaAssistant.xcodeproj -scheme TreeSeaAssistant \
    -destination "platform=iOS Simulator,id=$device" CODE_SIGNING_ALLOWED=NO test
 done
