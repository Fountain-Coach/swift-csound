# Csound.xcframework Placeholder

This directory is intentionally empty so that the repository can be opened on
platforms where the prebuilt `Csound.xcframework` artifact is not available.

To build the real Swift package on Apple platforms you must provide a
prebuilt `Csound.xcframework` that bundles the Csound static libraries and
public headers. Follow the instructions in the root `README.md` to produce the
framework, then place it at:

```
Artifacts/Csound.xcframework
```

The Swift Package manifest automatically links the binary target when the
package is resolved on Apple platforms.
