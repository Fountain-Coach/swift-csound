#if canImport(Darwin)
import Foundation
import Dispatch
import SPManager

@_silgen_name("csoundCreate")
private func csoundCreate(_ hostData: UnsafeMutableRawPointer?) -> OpaquePointer?

@_silgen_name("csoundDestroy")
private func csoundDestroy(_ handle: OpaquePointer?)

@_silgen_name("csoundCompileOrc")
private func csoundCompileOrc(_ handle: OpaquePointer?, _ orc: UnsafePointer<CChar>?) -> Int32

@_silgen_name("csoundReadScore")
private func csoundReadScore(_ handle: OpaquePointer?, _ score: UnsafePointer<CChar>?) -> Int32

@_silgen_name("csoundStart")
private func csoundStart(_ handle: OpaquePointer?) -> Int32

@_silgen_name("csoundStop")
private func csoundStop(_ handle: OpaquePointer?)

@_silgen_name("csoundSetControlChannel")
private func csoundSetControlChannel(_ handle: OpaquePointer?, _ name: UnsafePointer<CChar>?, _ value: Double) -> Int32

/// Errors thrown by ``CsoundBackend``.
public enum CsoundBackendError: Error {
    case initializationFailed
    case compilationFailed(String)
    case startFailed(Int32)
    case invalidState(String)
}

/// Concrete backend backed by a real Csound runtime.
public final class CsoundBackend: NSObject, SPBackend, @unchecked Sendable {
    private var handle: OpaquePointer?
    private var isRunning = false
    private let renderQueue = DispatchQueue(label: "fountaincoach.csound.render")

    public override init() {
        super.init()
    }

    public func prepare() async throws {
        if handle != nil { return }
        guard let instance = csoundCreate(nil) else {
            throw CsoundBackendError.initializationFailed
        }
        handle = instance
    }

    public func compile(program: SPProgram) async throws {
        guard let handle else {
            throw CsoundBackendError.invalidState("Csound has not been prepared")
        }

        guard case let .csound(orc, sco) = program else {
            throw CsoundBackendError.compilationFailed("Unsupported program type")
        }

        let orcResult = orc.withCString { csoundCompileOrc(handle, $0) }
        guard orcResult == 0 else {
            throw CsoundBackendError.compilationFailed("Orchestra compilation failed with code \(orcResult)")
        }

        let scoreResult = sco.withCString { csoundReadScore(handle, $0) }
        guard scoreResult == 0 else {
            throw CsoundBackendError.compilationFailed("Score compilation failed with code \(scoreResult)")
        }
    }

    public func start() async throws {
        guard let handle else {
            throw CsoundBackendError.invalidState("Csound has not been prepared")
        }
        guard !isRunning else { return }

        let result = csoundStart(handle)
        guard result == 0 else {
            throw CsoundBackendError.startFailed(result)
        }
        isRunning = true
    }

    public func stop() async throws {
        guard let handle else { return }
        if isRunning {
            csoundStop(handle)
            isRunning = false
        }
    }

    public func setControl(_ name: String, value: Double) async throws {
        guard let handle else {
            throw CsoundBackendError.invalidState("Csound has not been prepared")
        }

        let status = name.withCString { channel -> Int32 in
            csoundSetControlChannel(handle, channel, value)
        }

        guard status == 0 else {
            throw CsoundBackendError.invalidState("Failed to set control \(name)")
        }
    }

    public func teardown() async {
        if let handle {
            if isRunning {
                csoundStop(handle)
                isRunning = false
            }
            csoundDestroy(handle)
            self.handle = nil
        }
    }
}
#endif
