#!/bin/bash
set -euo pipefail
SIMULATOR_ID="${1:?Usage: scripts/test-ios.sh <dedicated-simulator-uuid> [derived-data-path]}"
DERIVED_DATA="${2:-/tmp/JXPagingView-SPM-DerivedData}"
cd "$(dirname "$0")/.."
xcodebuild -scheme JXPagingView \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath "$DERIVED_DATA" test
