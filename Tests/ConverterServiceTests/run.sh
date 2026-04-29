#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_BIN="${TMPDIR:-/tmp}/xyzmonitor_converter_tests"

swiftc \
  "$ROOT_DIR/XYZMonitor/Sources/Models.swift" \
  "$ROOT_DIR/XYZMonitor/Sources/ConverterService.swift" \
  "$ROOT_DIR/Tests/ConverterServiceTests/main.swift" \
  -o "$TEST_BIN"

"$TEST_BIN"
