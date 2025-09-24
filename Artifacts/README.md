# Csound.xcframework (7.0.0-beta.9)

> **Heads-up**
>
> The Codex evaluation environment that backs this repository cannot accept
> committed binary blobs. The XCFramework therefore is **not** checked into
> source control. Instead, use the helper script below on a macOS machine to
> (re)build the framework locally whenever you need to exercise the real
> Csound runtime.

## Contents

The generated xcframework should bundle the official binaries published in the
[`7.0.0-beta.9`](https://github.com/csound/csound/releases/tag/7.0.0-beta.9)
Csound release:

| Library identifier            | Slice details                     | Source artifact |
| ----------------------------- | --------------------------------- | --------------- |
| `ios-arm64`                   | static `libcsound.a` + headers    | `csound-ios-7.0.0-beta.9.zip`
| `ios-arm64-simulator`         | static `libcsound.a` + headers    | `csound-ios-7.0.0-beta.9.zip`
| `macos-arm64_x86_64`          | universal `CsoundLib64.framework` | `csound-macos-7.0.0-beta.9.zip`

All headers shipped by the upstream release are included so both Swift and
Objective-C callers can import `csound.h` (or the generated module `Csound`)
when building for iOS, iPadOS, macOS, tvOS, or watchOS.

## Generating the framework locally

1. Clone this repository on a macOS host with Xcode installed.
2. Download the `csound-ios-7.0.0-beta.9.zip` and
   `csound-macos-7.0.0-beta.9.zip` archives from the upstream GitHub release
   linked above.
3. Unpack the archives so you end up with directories that contain the
   `libcsound` libraries and associated headers.
4. Run the helper script provided in this folder, pointing each flag to the
   directories produced in the previous step:

   ```bash
   ./build_csound_xcframework.sh \
       --ios-arm64 /path/to/csound-ios-7.0.0-beta.9/ios-arm64 \
       --ios-simulator /path/to/csound-ios-7.0.0-beta.9/ios-arm64-simulator \
       --macos-arm64 /path/to/csound-macos-7.0.0-beta.9/macos-arm64 \
       --macos-x86_64 /path/to/csound-macos-7.0.0-beta.9/macos-x86_64
   ```

   The script wraps `xcodebuild -create-xcframework` and writes the result to
   `Artifacts/Csound.xcframework/`, a path that is gitignored so the binary
   never leaves your machine.
5. (Optional) Add `--zip` to the command to produce `Csound.xcframework.zip`
   and print its SwiftPM checksum if you plan to host the archive yourself.

The Swift package manifest is already configured to load the local xcframework
when present, so Xcode or `swift build` will immediately link against it.

## Checksums

SwiftPM binary target checksum (calculated with `swift package compute-checksum`)
for the zipped xcframework:

```
$ cd Artifacts
$ zip -r Csound.xcframework.zip Csound.xcframework
$ swift package compute-checksum Csound.xcframework.zip
```

*(Run the above if you need to re-host the artifact; the checksum is not stored
in this repository because SwiftPM reads the framework from disk.)*

## Updating the Framework

When a new Csound release drops repeat the generation steps above with the
fresh archives, then update this README with the new version number and
provenance details.

## Licensing

Csound is released under the LGPL. By bundling these binaries you agree to the
terms of the upstream license. Refer to the
[Csound license overview](https://csound.com/docs/licensing.html) for complete
information before redistributing the framework in your own products.

