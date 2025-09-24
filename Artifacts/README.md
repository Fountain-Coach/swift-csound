# Csound.xcframework Placeholder & Build Script

This directory holds the prebuilt `Csound.xcframework` that the Swift Package
expects when it is resolved on Apple platforms. The repository itself does not
ship the binary artifact; instead it provides documentation and a helper script
for producing one from locally built Csound libraries.

## Quick Recap

- Place the finished framework at `Artifacts/Csound.xcframework`.
- Commit the framework **only** if you intend to distribute the binary under an
  appropriate license.
- When the framework is absent (default in this repository) SwiftPM continues to
  work on non-Apple platforms thanks to the mock backend.

## Building the Framework

Use the `build_csound_xcframework.sh` helper to wrap your compiled Csound
libraries into an xcframework. The script runs on macOS (because it uses
`xcodebuild`) and expects you to provide per-architecture directories containing
`libcsound.a` (or `libcsound.dylib`) plus the matching public headers.

```
Artifacts/build_csound_xcframework.sh \
    --ios-arm64     /path/to/csound/ios-arm64 \
    --ios-simulator /path/to/csound/ios-sim-arm64 \
    --macos-arm64   /path/to/csound/macos-arm64 \
    --macos-x86_64  /path/to/csound/macos-x86_64 \
    --zip
```

Each supplied directory should look like:

```
macos-arm64/
├─ libcsound.a
└─ include/
```

The script will:

1. Validate that every provided directory contains a library and headers.
2. Invoke `xcodebuild -create-xcframework …` to produce
   `Artifacts/Csound.xcframework` (or a custom `--output`).
3. Optionally create a zipped archive and print its SwiftPM checksum when `--zip`
   is specified.

Refer to the root `README.md` for detailed build notes if you still need to
compile Csound for the relevant architectures.

## Verifying the Framework

After generating the framework you can sanity check it by inspecting the
embedded slices:

```
$ xcrun xcodebuild -showBuildSettings -project /dev/null # ensures Xcode CLI tools
$ lipo -info Artifacts/Csound.xcframework/macos-arm64/libcsound.a
```

You can also drop the zipped artifact into another Swift package, compute its
checksum, and declare it as a binary target for distribution.

## Cleaning Up

To reset the repository to its placeholder state simply remove the generated
framework:

```
rm -rf Artifacts/Csound.xcframework*
```

The mock backend will continue to function on platforms where the binary is not
available.
