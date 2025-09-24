#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: build_csound_xcframework.sh \
           --ios-arm64 <DIR> \
           --ios-simulator <DIR> \
           --macos-arm64 <DIR> \
           --macos-x86_64 <DIR> \
           [--watchos-arm64 <DIR>] \
           [--watchos-simulator <DIR>] \
           [--tvos-arm64 <DIR>] \
           [--tvos-simulator <DIR>] \
           [--output <PATH>] \
           [--zip]

Each <DIR> must contain a compiled libcsound.a (or libcsound.dylib) and an
include/ directory with the public headers for that slice. The script simply
wraps the xcodebuild -create-xcframework command so that the resulting
Csound.xcframework can be dropped into Artifacts/.

Examples of directory layouts (absolute paths recommended):
  ios-arm64/
    ├─ libcsound.a
    └─ include/
  macos-arm64/
    ├─ libcsound.a
    └─ include/

Set --zip to also produce Csound.xcframework.zip and print its SwiftPM
checksum. When --output is omitted the framework is written to
Artifacts/Csound.xcframework relative to this repository.
USAGE
}

ensure_dir() {
  local label="$1"
  local dir="$2"
  if [[ ! -d "$dir" ]]; then
    echo "error: missing directory for $label: $dir" >&2
    exit 1
  fi
  if [[ ! -f "$dir/libcsound.a" && ! -f "$dir/libcsound.dylib" ]]; then
    echo "error: $label directory does not contain libcsound.a or libcsound.dylib" >&2
    exit 1
  fi
  if [[ ! -d "$dir/include" ]]; then
    echo "error: $label directory does not contain an include/ directory" >&2
    exit 1
  fi
}

ARGS=("$@")
OUTPUT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/Artifacts/Csound.xcframework"
ZIP=false
LIB_ARGS=()

declare -A LABELS=(
  [--ios-arm64]="iOS arm64"
  [--ios-simulator]="iOS Simulator"
  [--macos-arm64]="macOS arm64"
  [--macos-x86_64]="macOS x86_64"
  [--watchos-arm64]="watchOS arm64"
  [--watchos-simulator]="watchOS Simulator"
  [--tvos-arm64]="tvOS arm64"
  [--tvos-simulator]="tvOS Simulator"
)

if [[ ${#ARGS[@]} -eq 0 ]]; then
  usage
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    --zip)
      ZIP=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --ios-arm64|--ios-simulator|--macos-arm64|--macos-x86_64|--watchos-arm64|--watchos-simulator|--tvos-arm64|--tvos-simulator)
      if [[ $# -lt 2 ]]; then
        echo "error: missing value for $1" >&2
        exit 1
      fi
      FLAG="$1"
      DIR="$2"
      ensure_dir "${LABELS[$FLAG]}" "$DIR"
      LIBNAME="libcsound.a"
      if [[ ! -f "$DIR/$LIBNAME" ]]; then
        LIBNAME="libcsound.dylib"
      fi
      LIB_ARGS+=("-library" "$DIR/$LIBNAME" "-headers" "$DIR/include")
      shift 2
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ${#LIB_ARGS[@]} -eq 0 ]]; then
  echo "error: no architectures provided" >&2
  usage
  exit 1
fi

FRAMEWORK_DIR="$(dirname "$OUTPUT")"
mkdir -p "$FRAMEWORK_DIR"

set -x
xcodebuild -create-xcframework "${LIB_ARGS[@]}" -output "$OUTPUT"
set +x

echo "Created $OUTPUT"

if $ZIP; then
  ZIP_PATH="$OUTPUT.zip"
  rm -f "$ZIP_PATH"
  (cd "$(dirname "$OUTPUT")" && ditto -c -k "$(basename "$OUTPUT")" "$(basename "$ZIP_PATH")")
  echo "Created $ZIP_PATH"
  if command -v swift >/dev/null 2>&1; then
    CHECKSUM=$(swift package compute-checksum "$ZIP_PATH")
    echo "SwiftPM checksum: $CHECKSUM"
  else
    echo "swift executable not available; skipped checksum calculation"
  fi
fi
