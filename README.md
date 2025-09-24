# FountainCoach Swift + Csound

> A clean, portable Swift Package that embeds **Csound** behind a pluggable,
concurrency-first manager (`SPManager`) — ready for FountainKit integration
today and promotable to **AUv3 (Apple)** and **LV2 (Linux)** tomorrow.

---

## Highlights

- **Pure Swift Core API**: `SPManager` (actor-based) with `SPBackend` protocol.
- **Csound Backend (optional)**: `SPCsoundBackend` wraps the Csound C API.
- **Mock Backend**: In-memory backend for tests and previews (no audio needed).
- **Future-Proof**: One DSP Core (C ABI) → thin adapters for AUv3/LV2.
- **FountainKit-Friendly**: Narrow surface, easy DI, no global state.

---

## Package Layout (conceptual)

```
Sources/
├─ SPManager/           # Pure Swift core (no Csound dependency)
│  ├─ SPTypes.swift
│  ├─ SPBackend.swift
│  ├─ SPManager.swift
│  └─ SPMockBackend.swift
├─ SPCsoundBackend/     # Optional: Swift wrapper over the Csound C API
│  ├─ CsoundBackend.swift
│  └─ (imports Csound systemLibrary or binary target)
└─ DSPCore/             # Optional: portable C/C++ DSP core (shared across targets)
AUv3Extension/          # Optional: AUv3 adapter (Apple platforms)
LV2/                    # Optional: LV2 adapter (Linux)
```

> You can use just `SPManager` + `SPCsoundBackend` and add AUv3/LV2 later.

---

## Requirements

- **Swift** 5.9+
- **Xcode** 15+ (for iOS/macOS dev)
- **Platforms**: iOS 15+, macOS 12+
- **Csound**: via Homebrew (macOS dev) or prebuilt `.xcframework` (iOS/macOS)
  - `brew install csound` (macOS local builds)
  - For iOS simulators/devices, bring a **prebuilt `Csound.xcframework`** or
    compile with CMake per-arch and combine with `xcodebuild -create-xcframework`.

---

## Installation (SwiftPM)

Add the package URL to your app/SDK:

```
https://github.com/Fountain-Coach/fountaincoach-swift-csound.git
```

In your target, depend on **SPManager** (required) and **SPCsoundBackend** (optional).

```swift
// Package.swift (excerpt)
.package(url: "https://github.com/Fountain-Coach/fountaincoach-swift-csound.git", from: "1.0.0"),

.target(
    name: "App",
    dependencies: [
        .product(name: "SPManager", package: "fountaincoach-swift-csound"),
        .product(name: "SPCsoundBackend", package: "fountaincoach-swift-csound")
    ]
)
```

The package manifest automatically wires the `SPCsoundBackend` target to a
prebuilt `Csound.xcframework` when the package is resolved on Apple platforms.
When developing on Linux the target falls back to a stub backend that throws so
that the package continues to load without the binary artifact.

---

## Quick Start (Swift)

```swift
import SPManager
// import SPCsoundBackend

let manager = SPManager()
let session: SPSessionID = "main"

#if canImport(SPCsoundBackend)
let backend = CsoundBackend()
#else
let backend = SPMockBackend() // builds without Csound present
#endif

try await manager.upsertSession(id: session, backend: backend)

let orc = """
sr = 48000
ksmps = 10
nchnls = 2
0dbfs = 1
instr 1
  kf chnget "freq"
  a1 oscili 0.2, kf
  outs a1, a1
endin
"""
let sco = "i1 0 60" // 60 seconds

try await manager.compile(id: session, program: .csound(orc: orc, sco: sco))
try await manager.start(id: session)
try await manager.setControl(id: session, "freq", value: 440)
```

> `perform()` is managed by the backend; it runs off the main thread. Call
`stop()` to end playback.

---

## Building/Linking Csound

### Option A: Prebuilt `Csound.xcframework` (recommended for iOS/macOS release)

The repository expects a prebuilt xcframework to be available at
`Artifacts/Csound.xcframework`. The directory ships with a `README` placeholder
and is ignored on Linux so that the SwiftPM manifest stays resolvable. To build
the xcframework:

1. Configure and build Csound per architecture and SDK using CMake.
2. Package the static libraries and headers into an xcframework:

   ```bash
   xcodebuild -create-xcframework \
     -library ios/arm64/libcsound.a -headers ios/arm64/include \
     -library iossim/arm64/libcsound.a -headers iossim/arm64/include \
     -library macos/arm64/libcsound.a -headers macos/arm64/include \
     -library macos/x86_64/libcsound.a -headers macos/x86_64/include \
     -output Csound.xcframework
   ```
3. Drop the resulting `Csound.xcframework` into `Artifacts/` before resolving the
   package in Xcode or SwiftPM.
4. The `SPCsoundBackend` target automatically links the binary and exposes a
   Swift-friendly API for the render lifecycle.

### Option B: System install (macOS development)
- `brew install csound`
- Use a SwiftPM `systemLibrary` target with a module map pointing at the brew headers/libs.

---

## Architecture & Migration Path

- **Today:** Embed via `SPManager` (Swift), using `SPCsoundBackend` for Csound.
- **Tomorrow:** Wrap the *same* DSP Core in
  - **AUv3** (`AUAudioUnit` → `dsp_render`) for Apple hosts, and
  - **LV2** (`run()` → `dsp_render`) for Linux hosts.

Keep the core rendering code engine-agnostic and allocation-free.

---

## Testing

- **Unit**: Core API, parameter round-trips, lifecycle.
- **Golden Audio**: Deterministic inputs → expected RMS/FFT signatures.
- **RT Stress**: Param spam, denormal checks, cancellation.
- **AUv3/LV2** (optional): AU validation, `lv2lint`.

---

## Roadmap

- [ ] Publish `SPManager` 1.0 API.
- [ ] Provide an official `Csound.xcframework` artifact for Apple platforms.
- [ ] Ship AUv3 demo adapter (host app + minimal UI).
- [ ] Ship LV2 adapter skeleton with CMake.
- [ ] Add Swift DocC and richer examples.

---

## License

_TBD by maintainers._ Add a `LICENSE` file at the repo root (MIT/Apache-2.0 recommended).
