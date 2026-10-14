#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(xcrun --find swift)" == */CommandLineTools/* ]]; then
  swift test --build-system native --package-path . \
    -Xswiftc -F -Xswiftc /Library/Developer/CommandLineTools/Library/Developer/Frameworks \
    -Xswiftc -plugin-path -Xswiftc /Library/Developer/CommandLineTools/usr/lib/swift/host/plugins "$@"
else
  swift test --package-path . "$@"
fi
