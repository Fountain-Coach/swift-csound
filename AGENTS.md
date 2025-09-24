# AGENTS.md

This document defines the **operational agents** and their responsibilities for the
Fountain Coach repository that implements **Swift + Csound** integration via a
pluggable `SPManager` architecture. Agents can be humans or automation
(workflows, bots). The goal is to keep the codebase shippable across Apple and
Linux targets while preserving a clean, testable core.

---

## Top-Level Principles

1. **One DSP Core, Many Adapters**
   - All sound-making logic lives in a portable C ABI (the *DSP Core*).
   - Swift (SPManager), AUv3 (Apple), and LV2 (Linux) are *thin adapters*.
2. **No RT Surprises**
   - The render path must be allocation-free, lock-free, and logging-free.
   - Parameter changes use lock-free queues or atomics and are applied at audio time.
3. **Reproducible Builds**
   - Prefer SwiftPM for Swift targets, CMake for LV2, and Xcode for AUv3.
   - Prebuilt artifacts (e.g., `Csound.xcframework`) are versioned and checksummed.
4. **FountainKit-Friendly**
   - The Swift layer exposes a narrow, async/await API and can be DI-injected into FountainKit.

---

## Agents & Scopes

### 1) **DSP Core Agent**
- **Scope:** `/Sources/DSPCore/**` (C/C++)
- **Responsibilities:**
  - Maintain the portable C ABI (`dsp_core.h`).
  - Render routine correctness (no locks/allocs) and denormal handling.
  - Parameter store (lock-free) and MIDI/event ingestion.
  - Provide golden-reference tests (RMS/FFT signatures).

### 2) **Swift Backend Agent**
- **Scope:** `/Sources/SPManager/**`, `/Sources/SPCsoundBackend/**`
- **Responsibilities:**
  - Implement `SPBackend` for Csound and the in-memory mock.
  - Manage lifecycle: `prepare → compile → start → perform → stop`.
  - Actor isolation & cancellation (no main-thread work in `perform`).
  - Public API stability and semantic versioning.

### 3) **Apple AUv3 Agent**
- **Scope:** `/AUv3Extension/**`, `/AUv3AppHost/**`
- **Responsibilities:**
  - Provide an `AUAudioUnit` adapter calling `dsp_render`.
  - Mirror parameters to `AUParameterTree` and wire automation/MIDI.
  - Run AU validation; keep the extension testable via AUv3 host app.

### 4) **Linux LV2 Agent**
- **Scope:** `/LV2/**`
- **Responsibilities:**
  - Implement LV2 manifest (`.ttl`) and plugin adapter to `dsp_core` (`run()`).
  - Map control/audio/MIDI ports to the shared param/event API.
  - Validate with `lv2lint` and test in Carla/Ardour.

### 5) **Build & Packaging Agent**
- **Scope:** CI/CD, artifacts (`.xcframework`), SPM manifests, CMake
- **Responsibilities:**
  - Produce and attach signed artifacts for releases.
  - Keep `Package.swift` accurate (targets, feature flags, minimum platforms).
  - Cache builds to speed up CI; verify checksums for binary targets.

### 6) **Docs Agent**
- **Scope:** `README.md`, `AGENTS.md`, API docs, examples
- **Responsibilities:**
  - Keep examples compiling and runnable.
  - Maintain architecture diagrams and migration notes (SPManager → AUv3/LV2).
  - Update usage snippets when APIs evolve.

### 7) **Security & Licensing Agent**
- **Scope:** Dependency review, license headers, notices
- **Responsibilities:**
  - Track Csound licensing for redistributed binaries (if any).
  - Ensure third-party compliance and export rules for artifacts.

---

## Decision Records (ADRs)

- Keep concise ADRs under `/docs/adr/`. Each agent may add an ADR when a design has durable impact (ABI changes, artifact policy, real-time constraints, etc.).

---

## Release Checklist (All Agents)

- [ ] CI green on macOS + Linux.
- [ ] Golden rendering tests pass and are stable.
- [ ] Artifacts uploaded (`Csound.xcframework` if applicable) with checksums.
- [ ] README install & snippet verified in a clean sample app.
- [ ] Semver updated, changelog appended.
